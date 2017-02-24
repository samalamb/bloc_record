require 'sqlite3'

 module Selection
   def find(id)
     row = connection.get_first_row <<-SQL
       SELECT #{columns.join ","} FROM #{table}
       WHERE id = #{id};
     SQL

     data = Hash[columns.zip(row)]
     new(data)
   end

   def find_by(attribute, value)
     row = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        WHERE #{attribute} = #{value}
     SQL

     for data in rows_to_array(rows)
      yield(data)
    end
   end
 end
