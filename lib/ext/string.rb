# encoding: utf-8

class String
  def escape
    newstr = gsub("\n", "\\n")
    newstr.gsub!('"', '\"')
    newstr
  end
end
