require File.dirname(__FILE__) + '/../spec_helper'

describe Sprinkle::Verify do
  before do
    @name = :package
    @package = package @name do
      gem 'nonexistent'
      verify do
        has_file 'my_file.txt'
        has_directory 'mydir'
      end
    end
    @verification = @package.verifications[0]
    @delivery = mock(Sprinkle::Deployment, :process => true)
    @verification.delivery = @delivery
  end
  
  describe 'when created' do
    it 'should raise error without a block' do
      lambda { Verify.new(nil, '') }.should raise_error
    end
  end
  
  describe 'with checks' do
    it 'should do a "test -f" on the has_file check' do
      @verification.commands.should include('test -f my_file.txt')
    end
    
    it 'should do a "test -d" on the has_directory check' do
      @verification.commands.should include('test -d mydir')
    end
  end
  
  describe 'with configurations' do
    # Make sure it includes Sprinkle::Configurable
    it 'should respond to configurable methods' do
      @verification.should respond_to(:defaults)
    end
    
    it 'should default failures option to /tmp' do
      @verification.failures.should eql('/tmp')
    end
  end
  
  describe 'with process' do
    it 'should raise an error when no delivery mechanism is set' do
      @verification.instance_variable_set(:@delivery, nil)
      lambda { @verification.process([]) }.should raise_error
    end
    
    describe 'when not testing' do
      before do
        # To be explicit
        Sprinkle::OPTIONS[:testing] = false
      end
      
      it 'should call process on the delivery with the correct parameters' do
        @delivery.should_receive(:process).with(@name, @verification.commands, [:app]).once
        @verification.process([:app])
      end
    end
    
    describe 'when testing' do
      before do
        Sprinkle::OPTIONS[:testing] = true
      end
      
      it 'should not call process on the delivery' do
        @delivery.should_not_receive(:process)
        @verification.process([:app])
      end
      
      after do
        Sprinkle::OPTIONS[:testing] = false
      end
    end
  end
end