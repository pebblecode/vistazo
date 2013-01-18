require_relative '../spec_helper'

describe "Date" do
  describe "week_range" do
    # Based on ISO 8601 date ranges
    # http://www.ruby-doc.org/core-1.9.3/Time.html#method-i-strftime
    @year_check = {
      # Years that starts before Thursday
      1999 => (1..52),
      2000 => (1..52),
      2001 => (1..52),
      2002 => (1..52),
      2003 => (1..52),

      # Years that starts on Thursday
      1992 => (1..53),
      1998 => (1..53),
      2004 => (1..53),
      2009 => (1..53),
      2015 => (1..53),

      # Year that after Thursday
      2005 => (1..52),
      2006 => (1..52),
      2007 => (1..52),
      2008 => (1..52)
    }

    @year_check.keys.each do |year|
      year_range = @year_check[year]
      it "should be #{year_range} for #{year}" do
        Date.week_range(year).should == year_range
      end
    end
  end

  describe "prev_week_year" do
    # Data format:
    #   year_to_check => {
    #     week_in_year => output
    #   }
    @data = {
      # A 53 week year
      2004 => {
        53 => 2004,
        52 => 2004,
        1 => 2003
      },

      # After a 53 week year
      2005 => {
        52 => 2005,
        1 => 2004
      }
    }

    @data.keys.each do |year|
      year_weeks = @data[year].keys
      year_weeks.each do |week|
        year_check = @data[year][week]
        it "should be #{year_check} for #{year} in week #{week}" do
          Date.prev_week_year(week, year).should == year_check
        end
      end
    end
  end

  describe "prev_week_num" do
    # Data format:
    #   year_to_check => {
    #     week_in_year => output
    #   }
    @data = {
      # A 53 week year
      2004 => {
        53 => 52,
        52 => 51,
        1 => 52
      },

      # After a 53 week year
      2005 => {
        52 => 51,
        1 => 53
      }
    }

    @data.keys.each do |year|
      year_weeks = @data[year].keys
      year_weeks.each do |week|
        year_check = @data[year][week]
        it "should be #{year_check} for #{year} in week #{week}" do
          Date.prev_week_num(week, year).should == year_check
        end
      end
    end
  end

  describe "next_week_year" do
    # Data format:
    #   year_to_check => {
    #     week_in_year => output
    #   }
    @data = {
      # A 53 week year
      2004 => {
        53 => 2005,
        52 => 2004,
        1 => 2004
      },

      # After a 53 week year
      2005 => {
        52 => 2006,
        1 => 2005
      }
    }

    @data.keys.each do |year|
      year_weeks = @data[year].keys
      year_weeks.each do |week|
        year_check = @data[year][week]
        it "should be #{year_check} for #{year} in week #{week}" do
          Date.next_week_year(week, year).should == year_check
        end
      end
    end
  end

  describe "next_week_num" do
    # Data format:
    #   year_to_check => {
    #     week_in_year => output
    #   }
    @data = {
      # A 53 week year
      2004 => {
        53 => 1,
        52 => 53,
        1 => 2
      },

      # After a 53 week year
      2005 => {
        52 => 1,
        1 => 2
      }
    }

    @data.keys.each do |year|
      year_weeks = @data[year].keys
      year_weeks.each do |week|
        year_check = @data[year][week]
        it "should be #{year_check} for #{year} in week #{week}" do
          Date.next_week_num(week, year).should == year_check
        end
      end
    end
  end
end