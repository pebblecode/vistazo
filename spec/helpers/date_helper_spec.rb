require_relative '../spec_helper'
require_relative '../../helpers/date_helper'

describe "DateHelper" do
  # include "DateHelper"

  describe "week_range" do
    it "should equal" do
      week_range(2012).should == "1"
    end
  end
end