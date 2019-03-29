module BMFFGlitch
  class Base
    attr_accessor :samples

    def initialize(path)
      @io = File.open(path, 'rb') 
      @file_container = BMFF::FileContainer.parse(@io)
      @samples = get_samples(@file_container)
    end
    
    def get_samples(file_container)
      samples = []
      file_container.select_descendants("trak").each do |trak|
        if !trak.select_descendants(BMFF::Box::VisualSampleEntry).empty?
          flag = BMFFGlitch::Sample::VISUALSAMPLE
        elsif !trak.select_descendants(BMFF::Box::AudioSampleEntry).empty?
          flag = BMFFGlitch::Sample::AUDIOSAMPLE
        elsif !trak.select_descendants(BMFF::Box::HintSampleEntry).empty?
          flag = BMFFGlitch::Sample::HINTSAMPLE
        else
          raise "Malformed trak"
        end
        
        box = trak.select_descendants("stsz")
        if (box == nil || box.empty?) 
          raise "Sample Size Boxes(stsz) is missing"
        end
        stsz = box[0]
        stsz.sample_count.times {|idx|
          # sample start with 1
          sample_number = idx + 1
          sample = BMFFGlitch::Sample.new(sample_number, flag)
          sample.size = (stsz.sample_size != 0) ? stsz.sample_size : stsz.entry_size[idx]
          samples.push(sample)
        }
    
        box = trak.select_descendants("stss")
        if box != nil && !box.empty?
          stss = box[0]
          stss.sample_number.each {|sample_number|
            sample = samples.find {|sample| (sample.sample_number == sample_number) && (sample.flag & flag != 0)}
            sample.flag |= BMFFGlitch::Sample::SYNCSAMPLE
          }
        end
        
        box = trak.select_descendants("ctts")
        if box != nil && !box.empty?
          ctts = box[0]
          sample_number = 1
          ctts.entry_count.times {|i|
            ctts.sample_count[i].times do
              sample = samples.find {|sample| (sample.sample_number == sample_number) && (sample.flag & flag != 0)}
              sample.sample_offset = ctts.sample_offset[i]
              sample_number += 1
            end
          }
        end
        
        box = trak.select_descendants("stts")
        if (box == nil || box.empty?) 
          raise "(Decoding)Time to Sample(stts) is missing"
        end
        stts = box[0]
        sample_number = 1
        stts.entry_count.times {|i|
          stts.sample_count[i].times do
            sample = samples.find {|sample| (sample.sample_number == sample_number) && (sample.flag & flag != 0)}
            sample.sample_delta = stts.sample_delta[i]
            sample_number += 1
          end
        }
        
        box = trak.select_descendants("stsc")
        if (box == nil || box.empty?) 
          raise "Sample Table Box(stsc) is missing"
        end
        stsc = box[0]
        
        box = trak.select_descendants("stco")
        if (box == nil || box.empty?) 
          raise "Chunk offset(stco) is missing"
        end
        stco = box[0]

        sample_number = 1
        chunk_number = 1
        stsc_idx = 0
        while (chunk_number <= stco.entry_count)
          if (stsc_idx == stsc.entry_count - 1 || chunk_number < stsc.first_chunk[stsc_idx+1])
            offset_from_chunk_offset = 0
            stsc.samples_per_chunk[stsc_idx].times do
              sample = samples.find {|sample| (sample.sample_number == sample_number) && (sample.flag & flag != 0)}
              sample.chunk_number = chunk_number
              sample.chunk_offset = stco.chunk_offset[chunk_number - 1]#chunk starts with 1
              sample.sample_description_index = stsc.sample_description_index[stsc_idx]
              sample.file_offset = sample.chunk_offset + offset_from_chunk_offset
              # prepare for next sample in the same chunk
              sample_number += 1
              offset_from_chunk_offset += sample.size
            end
            chunk_number += 1
          else
            stsc_idx += 1
          end
        end
      end

      @io.rewind
      samples.each {|sample|
        @io.seek(sample.file_offset, IO::SEEK_SET)
        sample.data = @io.read(sample.size)
      }
      return samples.sort {|a, b| a.file_offset <=> b.file_offset}
    end
    
    def update
      box = @file_container.select_descendants("mdat")
      if (box == nil || box.empty?)
        raise "Media Data Box(mdat) is missing"
      elsif (box.length > 2) # delete unnecessary mdat to ease re-calculate offset
        box.sort{|a,b| a.offset <=> b.offset }[1..box.length].each {|mdat| @file_container.children.delete(mdat) }
      end
      mdat = box[0]

      # data starts from mdat.offset + size(uint32) + type(uint32)
      mdat_data_offset = mdat.offset + 4 + 4
      
      # re-calculate offset
      # Because of the nature of sample-based glitch, we need to handle all samples individually.
      # I dare to disassemble chunks and each chunk contains only one sample
      @samples.each {|sample|
        sample.chunk_offset = mdat_data_offset
        sample.file_offset = sample.chunk_offset# file_offset and chunk_offset has the same value because each chunk has only one sample
        
        mdat_data_offset += sample.data.length
      }
      
      mdat.raw_data = @samples.map {|sample| sample.data }.join
      
      @file_container.select_descendants("trak").each do |trak|
        if !trak.select_descendants(BMFF::Box::VisualSampleEntry).empty?
          samples = @samples.find_all{|sample| sample.is_visualsample? }
        elsif !trak.select_descendants(BMFF::Box::AudioSampleEntry).empty?
          samples = @samples.find_all{|sample| sample.is_audiosample? }
        elsif !trak.select_descendants(BMFF::Box::HintSampleEntry).empty?
          samples = @samples.find_all{|sample| sample.is_hintsample? }
        else
          raise "Malformed trak"
        end

        # re-assign sample number and chunk number
        # sample_number starts from 1
        samples.each_with_index{|sample, i|
          sample.sample_number = i + 1
          sample.chunk_number = i + 1
        }
        
        box = trak.select_descendants("stsz")
        if (box == nil || box.empty?) 
          raise "Sample Size Boxes(stsz) is missing"
        end
        stsz = box[0]
        
        stsz.sample_count = samples.length
        size = samples.uniq{|sample| sample.size}
        if (size.length == 1) && (size[0].size != 0)
          # The size of all sample is the same, so we store the actual size in stsz.sample_size
          stsz.sample_size = size[0].size
          stsz.entry_size = []
        else
          # The size of sample varies(or all sample size is 0), we store each size in stsz.entry_size
          stsz.sample_size = 0
          stsz.entry_size = []
          # Do I have to sort samples?
          samples.each {|sample|
            stsz.entry_size.push(sample.size)
          }
        end
    
        box = trak.select_descendants("stss")
        if box != nil && !box.empty?
          stss = box[0]
          stss.sample_number = []
          samples.find_all {|sample| sample.is_syncsample?}.each {|sample|
            stss.sample_number.push(sample.sample_number)
          }
          stss.entry_count = stss.sample_number.length
        end
        
        box = trak.select_descendants("ctts")
        if box != nil && !box.empty?
          ctts = box[0]
          ctts.sample_count = []
          ctts.sample_offset = []
          sample_count = 0
          previous_sample_offset = nil
          samples.each{|sample|
            if (sample.sample_offset != previous_sample_offset)
              # store the previous values
              if (previous_sample_offset != nil)
                ctts.sample_count.push(sample_count)
                ctts.sample_offset.push(previous_sample_offset)
              end
              
              # prepare for the next value
              sample_count = 1
              previous_sample_offset = sample.sample_offset
            else
              sample_count += 1
            end
          }
          # store the last values
          ctts.sample_count.push(sample_count)
          ctts.sample_offset.push(previous_sample_offset)
          ctts.entry_count = ctts.sample_count.length
          
        end
    
        box = trak.select_descendants("stts")
        if box != nil && !box.empty?
          stts = box[0]
          stts.sample_count = []
          stts.sample_delta = []
          sample_count = 0
          previous_sample_delta = nil
          samples.each{|sample|
            if (sample.sample_delta != previous_sample_delta)
              # store the previous values
              if (previous_sample_delta != nil)
                stts.sample_count.push(sample_count)
                stts.sample_delta.push(previous_sample_delta)
              end
              # prepare for the next value
              sample_count = 1
              previous_sample_delta = sample.sample_delta
            else
              sample_count += 1
            end
          }
          # store the last values
          stts.sample_count.push(sample_count)
          stts.sample_delta.push(previous_sample_delta)
          stts.entry_count = stts.sample_count.length
        end
        
        box = trak.select_descendants("stco")
        if (box == nil || box.empty?) 
          raise "Chunk offset(stco) is missing"
        end
        stco = box[0]
        # Because of the nature of sample-based glitch, we need to handle all sample separately.
        # I dare to disassemble chunks and each chunk contains only one sample
        stco.entry_count = samples.length
        stco.chunk_offset = []
        samples.each {|sample|
          stco.chunk_offset.push(sample.chunk_offset)
        }
        
        box = trak.select_descendants("stsc")
        if (box == nil || box.empty?) 
          STDERR.puts "Sample Table Box(stsc) is missing"
          exit
        end
        stsc = box[0]
        # Because of the nature of sample-based glitch, we need to handle all samples individually.
        # I dare to disassemble chunks and each chunk contains only one sample

        stsc.first_chunk = []
        stsc.samples_per_chunk = []
        stsc.sample_description_index = []
        previous_sample_description_index = nil
        
        samples.each {|sample|
          if (sample.sample_description_index != previous_sample_description_index)
            stsc.first_chunk.push(sample.sample_number)
            stsc.samples_per_chunk.push(1)
            stsc.sample_description_index.push(sample.sample_description_index)
            previous_sample_description_index = sample.sample_description_index
          end
        }
        stsc.entry_count = stsc.first_chunk.length
      end
    end

    def output(path)
      update
      File.open(path, 'wb') do |f|
        f.write @file_container
      end
    end
  end
end
