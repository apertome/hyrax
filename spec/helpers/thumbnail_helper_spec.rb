require 'spec_helper'

describe CurationConcerns::ThumbnailHelper do
  let(:work) { GenericWork.new }
  let(:document) { SolrDocument.new work.to_solr }
  subject { helper.thumbnail_tag document, {} }

  context "with a representative" do
    before do
      allow(work).to receive(:representative).and_return('test-123')
    end
    it "draws the thumbnail" do
      expect(subject).to eq "<img alt=\"Thumbnail\" class=\"canonical-image\" " \
        "src=\"/downloads/test-123?file=thumbnail\" />"
    end
  end

  it "draws the default thumbnail" do
    expect(subject).to eq "<span class=\"canonical-image\"></span>"
  end
end
