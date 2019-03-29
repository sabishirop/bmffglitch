module BMFFGlitch
  class Sample
    VISUALSAMPLE = 1
    AUDIOSAMPLE = 2
    HINTSAMPLE = 4
    SYNCSAMPLE = 8

    attr_accessor :sample_number, :flag, :data, :size, :sample_offset, :sample_delta, :chunk_number, :chunk_offset, :file_offset, :sample_description_index
    def initialize(sample_number, flag)
      @sample_number = sample_number
      @flag = flag
      @data = ""
      @size = 0
      @sample_offset = 0
      @sample_delta = 0
      @chunk_number = 0
      @chunk_offset = 0
      @file_offset = 0
      @sample_description_index = 0
    end

    def initialize_copy(obj)
      # make deep copy
      @sample_number = obj.sample_number
      @flag = obj.flag
      @data = obj.data.dup
      @size = obj.size
      @sample_offset = obj.sample_offset
      @sample_delta = obj.sample_delta
      @chunk_number = obj.chunk_number
      @chunk_offset = obj.chunk_offset
      @file_offset = obj.file_offset
      @sample_description_index = obj.sample_description_index
    end
    
    def is_visualsample?
      (flag & VISUALSAMPLE) != 0 ? true : false
    end

    def is_audiosample?
      (flag & AUDIOSAMPLE) != 0 ? true : false
    end

    def is_hintsample?
      (flag & HINTSAMPLE) != 0 ? true : false
    end

    def is_syncsample?
      (flag & SYNCSAMPLE) != 0 ? true : false
    end
  end
end
