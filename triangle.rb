class Triangle

  def greeting
    text = "Please input 3 sides of triangle:\n"
    print text
    user_input
  end

  def user_input
    sides = validate gets.chomp
    unless sides
      print 'each 1 <= X <= 2000'
      greeting
    else
      count_type(sides)
    end
  end

  def count_type sides
    res = if ((sides[0] == sides[1]) && (sides[1] == sides[2]))
      'Equilateral'
    elsif ((sides[0] == sides[1]) || (sides[0] == sides[2]) || (sides[1] ==  sides[2]))
      'Isoceles'
    else
      'Scalene'
    end

    print res
    greeting
  end

  def validate sides_size
    sides = sides_size.split(' ')
    res = sides.each do |s|
      s = s.to_i
      break if s < 1 || s > 2000
    end
    (res.nil? || res.size != 2) ? false : res
  end
end

triangle = Triangle.new()
triangle.greeting