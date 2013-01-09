require_relative '../spec_helper'
require_relative '../../helpers/date_helper'

describe "DateHelper" do
  describe "week_range" do
    @year_check = {
      # A year that starts mid week and ends on sunday
      2000 => (0..52),
      # A year that starts on monday and ends mid week
      2001 => (1..53),
      # A year with 54 weeks (happens every 28 years)
      2012 => (0..53)
    }

    @year_check.keys.each do |year|
      year_range = @year_check[year]
      it "should be #{year_range} for #{year}" do
        week_range(year).should == year_range
      end
    end
  end

  describe "prev_week_year" do
    @data = {
      # A year that starts mid week and ends on sunday
      2000 => {
        2 => 2000,
        1 => 2000,
        0 => 1999
      },
      # A year that starts on monday and ends mid week
      2001 => {
        1 => 2000
      },
      # A year with 54 weeks (happens every 28 years)
      2012 => {
        0 => 2011
      }
    }

    @data.keys.each do |year|
      year_weeks = @data[year].keys
      year_weeks.each do |week|
        year_check = @data[year][week]
        it "should be #{year_check} for #{year} in week #{week}" do
          prev_week_year(week, year).should == year_check
        end
      end
    end
  end

  describe "prev_week_num" do
    @data = {
      # A year that starts mid week and ends on sunday
      2000 => {
        2 => 1,
        1 => 0,
        0 => 52
      },
      # A year that starts on monday and ends mid week
      2001 => {
        1 => 52
      },
      # A year with 54 weeks (happens every 28 years)
      2012 => {
        0 => 52
      }
    }

    @data.keys.each do |year|
      year_weeks = @data[year].keys
      year_weeks.each do |week|
        year_check = @data[year][week]
        it "should be #{year_check} for #{year} in week #{week}" do
          prev_week_num(week, year).should == year_check
        end
      end
    end
  end

  describe "next_week_year" do
    @data = {
      # A year that starts mid week and ends on sunday
      2000 => {
        2 => 2000,
        52 => 2001
      },
      # A year that starts on monday and ends mid week
      2001 => {
        52 => 2001,
        53 => 2002
      },
      # A year with 54 weeks (happens every 28 years)
      2012 => {
        53 => 2013
      }
    }

    @data.keys.each do |year|
      year_weeks = @data[year].keys
      year_weeks.each do |week|
        year_check = @data[year][week]
        it "should be #{year_check} for #{year} in week #{week}" do
          next_week_year(week, year).should == year_check
        end
      end
    end
  end

  describe "next_week_num" do
    @data = {
      # A year that starts mid week and ends on sunday
      2000 => {
        2 => 3,
        52 => 1
      },
      # A year that starts on monday and ends mid week
      2001 => {
        52 => 53,
        53 => 0
      },
      # A year with 54 weeks (happens every 28 years)
      2012 => {
        53 => 0
      }
    }

    @data.keys.each do |year|
      year_weeks = @data[year].keys
      year_weeks.each do |week|
        year_check = @data[year][week]
        it "should be #{year_check} for #{year} in week #{week}" do
          next_week_num(week, year).should == year_check
        end
      end
    end
  end
end