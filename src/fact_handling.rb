
class FactHandler






  #check if a object conforms to a field list
  #to help work out what its head template is
  def check fields, obj
    fields.each{ |field|
      if not obj.respond_to? field then
        return false
      end
    }
    return true
  end

end
