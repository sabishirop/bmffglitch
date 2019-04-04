RSpec.describe BMFFGlitch do
  before :all do
    FileUtils.mkdir OUTPUT_DIR unless File.exist? OUTPUT_DIR
    @in = FILES_DIR + 'sample.mp4'
    @in_faststart = FILES_DIR + 'sample_faststart.mp4'
    @out = OUTPUT_DIR + 'out.mp4'
  end

  after :each do
    FileUtils.rm Dir.glob((OUTPUT_DIR + '*').to_s)
  end

  after :all do
    FileUtils.rmdir OUTPUT_DIR
  end

  it "has a version number" do
    expect(BMFFGlitch::VERSION).not_to be nil
  end

  it "should return BMFFGlitch::Base object through the mothod #open" do
    bmff = BMFFGlitch.open(@in)
    expect(bmff).to be_kind_of BMFFGlitch::Base
  end

  it "should have the (almost) same samples when nothing is changed" do
    ibmff = BMFFGlitch.open(@in)
    ibmff.output(@out)

    obmff = BMFFGlitch.open(@out)
    expect(obmff.samples.length).to eq ibmff.samples.length
    obmff.samples.each_with_index {|sample, i|
      expect(sample.sample_number).to eq ibmff.samples[i].sample_number
      expect(sample.flag).to eq ibmff.samples[i].flag
      expect(sample.data).to eq ibmff.samples[i].data
      expect(sample.size).to eq ibmff.samples[i].size
      expect(sample.sample_offset).to eq ibmff.samples[i].sample_offset
      expect(sample.sample_delta).to eq ibmff.samples[i].sample_delta
      expect(sample.sample_description_index).to eq ibmff.samples[i].sample_description_index
      # chunk_number, chunk_offset, file_offset may differ because BMFFGlitch disassembles all chunks
    }
  end

  it "can glitch each sample"  do
    ibmff = BMFFGlitch.open(@in)
    ibmff.samples.each {|sample|
      #delete sample.data
      sample.data = ""
      sample.size = 0
    }
    ibmff.output(@out)

    obmff = BMFFGlitch.open(@out)
    obmff.samples.each_with_index {|sample, i|
      expect(sample.data).to eq ""
    }
  end

  it "can check whether BMFF file is fast-start of not"  do
    ibmff = BMFFGlitch.open(@in)
    expect(ibmff.is_faststart?).to eq false

    ifaststart_bmff = BMFFGlitch.open(@in_faststart)
    expect(ifaststart_bmff.is_faststart?).to eq true
  end

  it "should handle fast-start BMFF file correctly"  do
    ibmff = BMFFGlitch.open(@in_faststart)
    ibmff.samples.delete_if {|sample| sample.is_syncsample? && sample.sample_number != 1}
    ibmff_sample_data_list = ibmff.samples.map{|sample| sample.data}
    ibmff.output(@out)

    obmff = BMFFGlitch.open(@out)
    syncsample_num = obmff.samples.find_all {|sample| sample.is_syncsample?}.length
    expect(syncsample_num).to eq 1

    obmff.samples.each_with_index{|sample, i|
      expect(sample.data).to eq ibmff_sample_data_list[i]
    }
  end

end
