require 'spec_helper'

describe CharacterizeJob do
  let(:user) { FactoryGirl.find_or_create(:jill) }

  let(:generic_file) do
    GenericFile.create do |file|
      file.apply_depositor_metadata(user)
      Hydra::Works::AddFileToGenericFile.call(file, File.open(fixture_file_path('charter.docx')), :original_file)
    end
  end

  subject { CharacterizeJob.new(generic_file.id) }

  # Now that CreateDerivativesJob calls generic_file.create_derivatives directly
  # this test needs to be travis exempt. 
  it 'spawns a CreateDerivatives job', unless: $in_travis do
    expect(CurationConcerns::CharacterizationService).to receive(:run).with(generic_file)
    subject.run
  end
end
