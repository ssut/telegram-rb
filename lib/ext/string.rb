# encoding: utf-8

class String
  def escape!
    newstr = gsub("\n", "\\n")
    newstr.gsub!('"', '\"')
    replace "\"#{newstr}\""
  end
end
