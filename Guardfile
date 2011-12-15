
# Generated from http://github.com/guard/guard-minitest
# guard 'minitest' do
#   # with Minitest::Unit
#   watch(%r|^test/test_(.*)\.rb|)
#   watch(%r|^lib/(.*)([^/]+)\.rb|)     { |m| "test/#{m[1]}test_#{m[2]}.rb" }
#   watch(%r|^test/test_helper\.rb|)    { "test" }
# 
#   # with Minitest::Spec
#   watch(%r|^spec/(.*)_spec\.rb|)
#   watch(%r|^lib/(.*)\.rb|)            { |m| "spec/#{m[1]}_spec.rb" }
#   watch(%r|^spec/spec_helper\.rb|)    { "spec" }
# end

# Generated from http://github.com/guard/guard-rspec
guard 'rspec', :cli => '--color', :version => 2 do
  watch(%r{^models/(.+)\.rb$})
  
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})             { "spec" } #{ |m| "spec/lib/#{m[1]}_spec.rb" }
  
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})             { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch(%r{^spec/support/(.+)\.rb$})    { "spec" }
  watch('spec/spec_helper.rb')          { "spec" }
  
  watch('web.rb')                       { "spec" }
  
  # Capybara integration specs
  watch(%r{^views/(.+)\.erb$})          { |m| "spec/integration" }
end

