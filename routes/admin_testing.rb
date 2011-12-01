class VistazoApp < Sinatra::Application
  post '/reset' do
    protected!
  
    # Delete everything
    TeamMember.delete_all()
    Project.delete_all()
    ColourSetting.delete_all()
    Account.delete_all()
  
    # Seed data
    pebble_code_web_dev = Account.create(:name => "pebble{code} web-dev team", :url_slug => "pebble_code_web_dev")
    pebble_code_web_dev.update_attributes(:projects => [
      Project.create(:name => "ideapi"),
      Project.create(:name => "Space"),
      Project.create(:name => "LDN taxi"),
      Project.create(:name => "Vistazo")
    ])
    pebble_code_web_dev.update_attributes(:team_members => [
      TeamMember.create(:name => "Toby H"),
      TeamMember.create(:name => "George O"),
      TeamMember.create(:name => "Mark D"),
      TeamMember.create(:name => "Tak T"),
      TeamMember.create(:name => "Vince M"),
    ])
  
    pebble_code_dot_net = Account.create(:name => "pebble{code} .net team", :url_slug => "pebble_code_dot_net")
    pebble_code_dot_net.update_attributes(:projects => [
      Project.create(:name => "Contrarius"),
      Project.create(:name => "Bingo")
    ])
    pebble_code_dot_net.update_attributes(:team_members => [
      TeamMember.create(:name => "Toby H"),
      TeamMember.create(:name => "Alex B"),
      TeamMember.create(:name => "Greg J"),
      TeamMember.create(:name => "Matt W"),
      TeamMember.create(:name => "Daniel B")
    ])
  
    pebble_it = Account.create(:name => "pebble.it", :url_slug => "pebble_it")
    pebble_it.update_attributes(:projects => [
      Project.create(:name => "Frukt"),
      Project.create(:name => "Kane")
    ])
    pebble_it.update_attributes(:team_members => [
      TeamMember.create(:name => "Toby H"),
      TeamMember.create(:name => "Seb N"),
      TeamMember.create(:name => "Paul E"),
      TeamMember.create(:name => "David O"),
      TeamMember.create(:name => "Graham G"),
      TeamMember.create(:name => "Simon T"),
      TeamMember.create(:name => "Michael P"),
      TeamMember.create(:name => "James F"),
      TeamMember.create(:name => "Toby TAG G"),
      TeamMember.create(:name => "Gayle S")
    ])

    flash[:success] = "Successfully cleared out the database and added seed data. Enjoy!"
    redirect '/'
  end
end