require_relative '../spec_helper'
require_relative '../../helpers/date_helper'

describe "DateHelper" do
  # include "DateHelper"

  describe "week_range" do
    describe "for 54 week year that starts mid week and ends mid week)" do
      it "should equal 0..53" do
        week_range(2000).should == (0..53)
      end
    end

    describe "for 53 week year that ends mid week" do
      it "should equal 1..53" do
        week_range(2012).should == (1..53)
      end
    end

    describe "for 53 week year that starts mid week" do
      it "should equal 0..52" do
        week_range(2001).should == (0..52)
      end
    end
  end

  describe "prev_week_num" do
    describe "for week 3 in year 2000" do
      it "should equal 2" do
        prev_week_num(3, 2000).should == 2
      end
    end

    describe "for week 1 in year 2000" do
      it "should equal 0" do
        prev_week_num(1, 2000).should == 0
      end
    end

    describe "for week 0 in year 2000" do
      it "should equal 52" do
        prev_week_num(0, 2000).should == 52
      end
    end

    describe "for week 0 in year 2013" do
      it "should equal 53" do
        prev_week_num(0, 2013).should == 53
      end
    end
  end

  describe "next_week_num" do
    describe "for week 3 in year 2000" do
      it "should equal 4" do
        next_week_num(3, 2000).should == 4
      end
    end

    describe "for week 52 in year 2000" do
      it "should equal 53" do
        next_week_num(52, 2000).should == 53
      end
    end

    describe "for week 53 in year 2000" do
      it "should equal 0" do
        next_week_num(53, 2000).should == 0
      end
    end

    describe "for week 52 in year 2001" do
      it "should equal 1" do
        next_week_num(52, 2001).should == 0
      end
    end
  end
end