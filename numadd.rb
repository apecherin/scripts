class Numadd
  def initialize
    @sum = 0
  end

  def greeting
    text = "Find 3 numbers to a sum\n=======================\n\nThis program identifies 3 numbers abc, def and ghi, the sum of which equals the user typed number. The digits of the 3 identified numbers are all different(no digit appears twice).\n"
    text = text + "\n\tExample: \n\t abc \n\t def \n\t ghi \n\t --- \n\t number\n\n\n"
    print text
  end

  def user_input
    text = "Type a number with 3 or 4 digits: "
    print text
    sum = gets.chomp
    return false if sum == "exit"
    if sum.size > 4 || sum.size < 3
      print "incorrect input\n\n"
      user_input
    end

    @sum = sum.to_i
    if @sum == 0
      print "incorrect input\n\n"
      user_input
    end

    output_sum
  end

  def output_sum
    sum = calculate_sum
    text = sum.join("\n\t")
    text = "\nSolution:\n\t" + text + "\n\t---" + "\n\t#{@sum}\n\n"

    print text
    user_input
  end


private

  def calculate_sum
    fib_array = (0..20).map { |n| fib(n) }
    i = 0
    fib_array.each do |n|
      if n > @sum
        z = fib_array[i - 3]
        y = fib_array[i - 2]
        x = @sum - (z + y)
        break [x, y, z]
      end
      i+=1
    end
  end

  def fib (n)
    return 0 if n == 0

    x = 0
    y = 1

    (1..n).each do
      z = (x + y)
      x = y
      y = z
    end

    return y
  end
end

numadd = Numadd.new()
numadd.greeting
numadd.user_input
