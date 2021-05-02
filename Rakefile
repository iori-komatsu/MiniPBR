require 'pathname'
require 'rake'
require 'set'

#--------------------------------------------------------------------------------------------------

def resolve_include_path(included_file, hlsl_file, bracket)
  case bracket 
  when '"'
    included_file = Pathname.new(included_file)
    hlsl_file = Pathname.new(hlsl_file)
    (hlsl_file.dirname + included_file).to_s
  when '<'
    included_file = Pathname.new(included_file)
    (Pathname.new(".") + included_file).to_s
  else
    fail "Unknown bracket: #{bracket}"
  end
end

$dependencies = {}

def resolve_dependencies(hlsl_file)
  if $dependencies.key?(hlsl_file)
    return $dependencies[hlsl_file]
  end

  content = IO.read(hlsl_file)
  content.force_encoding("Windows-31J")

  deps = Set.new
  content.scan(/^\s*\#\s*include\s*([<"])([^>"]+)[">]\s*$/sm) do |s|
    f = resolve_include_path(s[1], hlsl_file, s[0])
    deps.add(f)
    deps.merge(resolve_dependencies(f))
  end

  $dependencies[hlsl_file] = deps
  deps
end

#--------------------------------------------------------------------------------------------------

hlsl_files = FileList["**/*.hlsl"]

hlsl_files.each do |hlsl_file|
  fx_file = hlsl_file.pathmap("%X.fx")
  deps = [hlsl_file] + resolve_dependencies(hlsl_file).to_a
  file fx_file => deps do
    sh "fxc /nologo /Gec /O1 /T fx_2_0 /I . #{hlsl_file} /Fo #{fx_file}"
  end
end

task default: hlsl_files.pathmap("%X.fx")
