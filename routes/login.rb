class VistazoApp < Sinatra::Application
  get '/oauth' do
    protected!
    erb :oauth
  end
  
  get '/auth/:provider/callback' do
    content_type 'text/plain'
    request.env['omniauth.auth'].to_hash.inspect rescue puts "No Data"
  end

  get '/auth/failure' do
    content_type 'text/plain'
    request.env['omniauth.auth'].to_hash.inspect rescue "No Data"
  end
end