# encoding: utf-8

class String
  def escape!
    newstr = gsub("\n", "\\n")
    replace "\"#{newstr}\""
  end
end
