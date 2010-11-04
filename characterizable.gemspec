# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{characterizable}
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Andy Rossmeissl", "Seamus Abshere"]
  s.date = %q{2010-11-04}
  s.description = %q{Characterize the relationship between "attributes" (getters/setters) of instances of a class}
  s.email = %q{seamus@abshere.net}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "characterizable.gemspec",
     "lib/characterizable.rb",
     "lib/characterizable/base.rb",
     "lib/characterizable/better_hash.rb",
     "lib/characterizable/characteristic.rb",
     "lib/characterizable/snapshot.rb",
     "test/characterizable/test_characteristic.rb",
     "test/helper.rb",
     "test/test_characterizable.rb"
  ]
  s.homepage = %q{http://github.com/seamusabshere/characterizable}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Characterize instances of a class}
  s.test_files = [
    "test/characterizable/test_characteristic.rb",
     "test/helper.rb",
     "test/test_characterizable.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<blockenspiel>, [">= 0.3.2"])
      s.add_runtime_dependency(%q<activesupport>, [">= 2.3.5"])
      s.add_development_dependency(%q<shoulda>, [">= 0"])
    else
      s.add_dependency(%q<blockenspiel>, [">= 0.3.2"])
      s.add_dependency(%q<activesupport>, [">= 2.3.5"])
      s.add_dependency(%q<shoulda>, [">= 0"])
    end
  else
    s.add_dependency(%q<blockenspiel>, [">= 0.3.2"])
    s.add_dependency(%q<activesupport>, [">= 2.3.5"])
    s.add_dependency(%q<shoulda>, [">= 0"])
  end
end

