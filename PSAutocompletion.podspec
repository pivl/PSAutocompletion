Pod::Spec.new do |s|
  s.name         = "PSAutocompletion"
  s.version      = "1.0.0"
  s.summary      = "PSAutocompletion for UITextField Safari-like search/address bar"
  s.description  = <<-DESC
                   PSAutocompletion is a class that creates behaviour similar to
                   Safari or Chrome search/address bar. Just create a data source
                   that returns required text
                   DESC

  s.homepage     = "https://github.com/pivl/PSAutocompletion"
  s.license      = "MIT"
  s.author             = { "Pavel Stasyuk" => "pivlyak@gmail.com" }

  s.ios.deployment_target = "8.0"

  s.source       = { :git => "https://github.com/pivl/PSAutocompletion.git", :tag => s.version.to_s }
  s.source_files = "PSAutocompletion/PSAutocompletion.swift"
end
