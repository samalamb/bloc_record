module BlocRecord
  class Collection < Array

    def update_all(updates)
      ids = self.map(&:id)

      self.any? ? self.first.class.update(ids, updates) : false
    end

    def take(lim=1)
      if self.any?
        self[0...lim]
      else
        nil
      end
    end

    def where(options)
      if args.count > 1
         expression = args.shift
         params = args
       else
         case args.first
         when String
           expression = args.first
         when Hash
           if args.first.keys[0] == nil
             expression_hash = BlocRecord::Utility.convert_keys(args.first)
             expression = expression_hash.map { |key, value| "#{key} IS NOT NULL" }
           else
             expression_hash = BlocRecord::Utility.convert_keys(args.first)
             expression = expression_hash.map { |key, value| "#{key} = #{BlocRecord::Utility.sql_strings(value)}"}.join(" AND ")
           end
         end

         self.any? ? self.first.class.where(expression) : false
       end
    end

    def not
      if args.count > 1
         expression = args.shift
         params = args
       else
         case args.first
         when String
           expression = args.first
         when Hash
           if args.first.keys[0] == nil
             expression_hash = BlocRecord::Utility.convert_keys(args.first)
             expression = expression_hash.map { |key, value| "#{key} IS NOT NULL" }
           else
             expression_hash = BlocRecord::Utility.convert_keys(args.first)
             expression = expression_hash.map { |key, value| "#{key} <> #{BlocRecord::Utility.sql_strings(value)}"}.join(" AND ")
           end
         end

         self.any? ? self.first.class.where(expression) : false
       end
    end
  end
end
