require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

RSpec.describe BMFFGlitch, 'bmffdtmsh cli' do

  before :all do
    FileUtils.mkdir OUTPUT_DIR unless File.exist? OUTPUT_DIR
    @in = FILES_DIR + 'sample.mp4'
    @out = OUTPUT_DIR + 'out.mp4'
    here = File.dirname(__FILE__)
    lib = Pathname.new(File.join(here, '..', 'lib')).realpath
    bmfgdtmsh = Pathname.new(File.join(here, '..', 'bin/bmffdtmsh')).realpath
    @cmd = "ruby -I%s %s -o %s " % [lib, bmfgdtmsh, @out]
  end

  after :each do
    FileUtils.rm Dir.glob((OUTPUT_DIR + '*').to_s)
  end

  after :all do
    FileUtils.rmdir OUTPUT_DIR
  end

  it 'should remove all syncsample except the first one' do

    bmff_orig = BMFFGlitch.open(@in)
    orig_sample_num = bmff_orig.samples.length
    orig_syncsample_num = bmff_orig.samples.find_all{|sample| sample.is_syncsample?}.length
    system [@cmd, @in].join(' ')

    bmff_dtmshed = BMFFGlitch.open(@out)
    dtmshed_sample_num = bmff_dtmshed.samples.length
    dtmshed_syncsample_num = bmff_dtmshed.samples.find_all{|sample| sample.is_syncsample?}.length
    dtmshed_syncsamples= bmff_dtmshed.samples.find_all{|sample| sample.is_syncsample?}

    # bbfmdtmsh should preserve 1st syncsample
    expect(dtmshed_syncsample_num).to eq 1
    expect(dtmshed_sample_num).to eq (orig_sample_num - orig_syncsample_num + 1)
  end

  it 'should remove all syncsample when called with -a option' do
    bmff_orig = BMFFGlitch.open(@in)
    orig_sample_num = bmff_orig.samples.length
    orig_syncsample_num = bmff_orig.samples.find_all{|sample| sample.is_syncsample?}.length

    system [@cmd, '-a', @in].join(' ')
    bmff_dtmshed_all = BMFFGlitch.open(@out)
    dtmshed_sample_num = bmff_dtmshed_all.samples.length
    dtmshed_syncsample_num = bmff_dtmshed_all.samples.find_all{|sample| sample.is_syncsample?}.length

    expect(dtmshed_syncsample_num).to eq 0
    expect(dtmshed_sample_num).to eq (orig_sample_num - orig_syncsample_num)
  end
end
