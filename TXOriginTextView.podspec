Pod::Spec.new do |s|

s.name         = "TXOriginTextView"
s.version      = "1.0"
s.summary      = "A short description of TXOriginTextView."


s.description  = "this is a view of origin text"

s.homepage     = "https://github.com/AlenBo/TXOriginTextView"

s.license      = "MIT"

s.author             = { "AlenBo" => "447699760@qq.com" }
s.platform     = :ios, "8.0"

s.source       = { :git => "https://github.com/AlenBo/TXOriginTextView.git", :tag => "#{s.version}" }

s.source_files  = "TapLabelView/*"
s.requires_arc = true

  end
