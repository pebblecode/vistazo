# The main routes for the core of the app
class VistazoApp < Sinatra::Application
  get '/' do
    protected!
  
    @accounts = Account.all
  
    erb :homepage
  end
  
  # Vistazo weekly view - the crux of the app
  get '/:account/:year/week/:week_num' do
    protected!

    @account = Account.find_by_url_slug(params[:account])

    if @account.present?
      year = params[:year].to_i
      week_num = params[:week_num].to_i

      if ((1..NUM_WEEKS_IN_A_YEAR).include? week_num) and (year > START_YEAR)
        # Weeks start from 1
        prev_week_num = ((week_num - 1) <= 0) ? NUM_WEEKS_IN_A_YEAR : week_num - 1
        prev_week_year = ((week_num - 1) <= 0) ? year - 1 : year
        @prev_week_url = (prev_week_year > START_YEAR) ? "/#{params[:account]}/#{prev_week_year}/week/#{prev_week_num}" : nil

        next_week_num = ((week_num + 1) > NUM_WEEKS_IN_A_YEAR) ? 1 : week_num + 1
        next_week_year = ((week_num + 1) > NUM_WEEKS_IN_A_YEAR) ? year + 1 : year
        @next_week_url = "/#{params[:account]}/#{next_week_year}/week/#{next_week_num}"

        @monday_date = Date.commercial(year, week_num, MONDAY)
        @tuesday_date = Date.commercial(year, week_num, TUESDAY)
        @wednesday_date = Date.commercial(year, week_num, WEDNESDAY)
        @thursday_date = Date.commercial(year, week_num, THURSDAY)
        @friday_date = Date.commercial(year, week_num, FRIDAY)

        @projects = Project.where(:account_id => @account.id).sort(:name)
        @team_members = TeamMember.where(:account_id => @account.id).sort(:name)

        # Assume it's the right week of dates
        @team_member_projects_on_day = {}
        for tm in @team_members do
          @team_member_projects_on_day[tm] = {}

          (MONDAY..FRIDAY).each do |work_day|
            @team_member_projects_on_day[tm][work_day] = tm.team_member_projects.select { |proj| 
              (proj.date.wday == work_day) and (proj.date >= @monday_date) and (proj.date <= @friday_date)
            }
          end
        end

        erb :week
      else
        flash.next[:warning] = "Invalid week and year."
        redirect "/#{params[:account]}"
      end
    else
      flash.next[:warning] = "Invalid account."
      redirect '/'
    end
  end
  
  get '/css/style.css' do
    scss "sass/style".intern
  end
end