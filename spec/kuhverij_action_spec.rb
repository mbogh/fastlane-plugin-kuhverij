describe Fastlane::Actions::KuhverijAction do
  let(:fixtures_path) { File.expand_path("./spec/fixtures") }

  describe '#run' do
    it 'raises exception if no xccovreport can be found in the derived data folder' do
      expect do
        Fastlane::Actions::KuhverijAction.run(derived_data_path: "./lib")
      end.to raise_exception("No '.xccovreport' could be found at ./lib")
    end

    it 'formats the xccov command correctly' do
      derived_data_path = fixtures_path + "/dummy"
      xccovreport_path = derived_data_path + "/dummy.xccovreport"

      command = "xcrun xccov view --only-targets --json #{xccovreport_path.shellescape}"
      command_result = "[]"
      allow(Fastlane::Actions).to receive(:sh).with(command, log: false).and_return(command_result)

      result = Fastlane::Actions::KuhverijAction.run(derived_data_path: derived_data_path)

      expect(result.size).to eq(1)
      expect(result[0]).to eq(command)
    end

    it 'prints message with code coverage' do
      derived_data_path = fixtures_path + "/dummy"
      xccovreport_path = derived_data_path + "/dummy.xccovreport"

      command = "xcrun xccov view --only-targets --json #{xccovreport_path.shellescape}"
      command_result = File.read(fixtures_path + "/advanced_report.json")
      allow(Fastlane::Actions).to receive(:sh).with(command, log: false).and_return(command_result)

      expect(Fastlane::UI).to receive(:message).with("Code Coverage: 16.97%")
      Fastlane::Actions::KuhverijAction.run(derived_data_path: derived_data_path)
    end

    it 'reports 0.00% code coverage if there are 0 lines covered in .app and .framework' do
      derived_data_path = fixtures_path + "/dummy"
      xccovreport_path = derived_data_path + "/dummy.xccovreport"

      command = "xcrun xccov view --only-targets --json #{xccovreport_path.shellescape}"
      command_result = File.read(fixtures_path + "/zero_coverage_report.json")
      allow(Fastlane::Actions).to receive(:sh).with(command, log: false).and_return(command_result)

      expect(Fastlane::UI).to receive(:message).with("Code Coverage: 0.00%")
      Fastlane::Actions::KuhverijAction.run(derived_data_path: derived_data_path)
    end
  end

  describe 'meta' do
    it 'has the testing category' do
      expect(Fastlane::Actions::KuhverijAction.category).to eq(:testing)
    end

    it 'supports Mac platform' do
      expect(Fastlane::Actions::KuhverijAction.is_supported?(:mac)).to eq(true)
    end

    it 'supports iOS platform' do
      expect(Fastlane::Actions::KuhverijAction.is_supported?(:ios)).to eq(true)
    end

    it 'does not support Android platform' do
      expect(Fastlane::Actions::KuhverijAction.is_supported?(:android)).to eq(false)
    end
  end

  describe 'Fastfile usage' do
    it 'prints a message when values come from SharedValues' do
      derived_data_path = fixtures_path + "/dummy"
      xccovreport_path = derived_data_path + "/dummy.xccovreport"

      command = "xcrun xccov view --only-targets --json #{xccovreport_path.shellescape}"
      command_result = File.read(fixtures_path + "/advanced_report.json")
      allow(Fastlane::Actions).to receive(:sh).with(command, log: false).and_return(command_result)

      Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::SCAN_DERIVED_DATA_PATH] = derived_data_path

      expect(Fastlane::UI).to receive(:message).with("Code Coverage: 16.97%")
      Fastlane::FastFile.new.parse("lane :test do
        kuhverij()
      end").runner.execute(:test)
    end
  end
end
