require 'sqlite3'

module Selection
  def find(*ids)
    if ids.kind_of? String || id <= 0
      puts "Sorry please enter a number that is greater than 0."
    elsif ids.length == 1
      find_one(ids.first)
    else
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
          WHERE id IN (#{ids.join(",")});
      SQL

      rows_to_array(rows)
    end
  end

  def find_one(id=1)
    if id.is_a?(Integer)
      row = connection.get_first_row <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        WHERE id = #{id};
      SQL

      init_object_from_row(row)
    else
      puts "Sorry, please enter a number"
    end
  end

  def find_by(attribute, value)
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
    SQL

    init_object_from_row(row)
  end

  def find_each(*options = {})
    if options.nil?
      items = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
      SQL
    else
      items = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        LIMIT #{options.size} OFFSET #{options.start};
      SQL
    end

    items.each do |item|
      yield init_object_from_row(item)
    end
  end

  def find_in_batches(options = {})
    items = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      LIMIT #{options.size} OFFSET #{options.start};
    SQL

    if items.nil?
      nil
    else
      yield rows_to_array(items)
    end
  end

  def self.method_missing(method_sym, *arguments)
    if method_sym.to_s =~ /find_by/
      if args.length > 1
        puts "please provide only one argument"
        method_missing(method_sym, *args)
      end
      attribute = nil
      value = nil
      attribute = method_sym.to_s[7...method.length].downcase
      attribute.slice!(0) if attribute[0] == "_"

      if self.attributes.include?(attribute)
        args.each do |arg|
          if arg.class == String
            value = arg
          else
            value = arg.to_s
          end
        end

        find_by(attribute, value)
      else
        super
      end
    else
      super
    end
  end

  def take(num=1)
    if num > 1
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        ORDER BY random()
        LIMIT #{num};
      SQL

      rows_to_array(rows)
    else
      take_one
    end
  end

  def take_one
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY random()
      LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def first
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id
      ASC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def last
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id
      DESC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def all
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table};
    SQL

    rows_to_array(rows)
  end

  private
  def init_object_from_row(row)
    if row
      data = Hash[columns.zip(row)]
      new(data)
    end
  end

  def rows_to_array(rows)
    rows.map { |row| new(Hash[columns.zip(row)]) }
  end
end
