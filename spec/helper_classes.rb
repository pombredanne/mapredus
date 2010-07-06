class GetWordCount < MapRedus::Process
  TEST = "He pointed his finger in friendly jest and went over to the parapet laughing to himself. Stephen Dedalus stepped up, followed him wearily halfway and sat down on the edge of the gunrest, watching him still as he propped his mirror on the parapet, dipped the brush in the bowl and lathered cheeks and neck."
  EXPECTED_ANSWER = {"gunrest"=>1, "over"=>1, "still"=>1, "of"=>1, "him"=>2, "and"=>4, "bowl"=>1, "himself"=>1, "went"=>1, "friendly"=>1, "finger"=>1, "propped"=>1, "cheeks"=>1, "dipped"=>1, "down"=>1, "wearily"=>1, "up"=>1, "stepped"=>1, "dedalus"=>1, "to"=>2, "in"=>2, "sat"=>1, "the"=>6, "pointed"=>1, "as"=>1, "followed"=>1, "stephen"=>1, "laughing"=>1, "his"=>2, "he"=>2, "brush"=>1, "jest"=>1, "neck"=>1, "mirror"=>1, "edge"=>1, "on"=>2, "parapet"=>2, "lathered"=>1, "watching"=>1, "halfway"=>1}
  def self.specification
    {
      :inputter => WordStream,
      :mapper => WordCounter,
      :reducer => Adder,
      :finalizer => ToRedisHash,
      :outputter => MapRedus::RedisHasher,
      :ordered => false,
      :keyname => "test:result"
    }
  end
end

class WordStream < MapRedus::InputStream
  def self.scan(data_object)
    #
    # The data_object should be a reference to an object that is
    # stored on your system.  The scanner is used to break up what you
    # need from the object into manageable pieces for the mapper.  In
    # this example, the data object is a reference to a redis string.
    #
    test_string = MapRedus::FileSystem.get(data_object)
    
    test_string.split.each_slice(10).each_with_index do |word_set, i|
      yield(i, word_set.join(" "))
    end
  end
end

class WordCounter < MapRedus::Mapper
  def self.map(map_data)
    map_data.split(/\W/).each do |word|
      next if word.empty?
      yield(word.downcase, 1)
    end
  end
end

class CharCounter < MapRedus::Mapper
  def self.map(map_data)
    map_data.each do |char|
      yield(char, 1)
    end
  end
end

class Adder < MapRedus::Reducer
  def self.reduce(value_list)
    yield( value_list.reduce(0) { |r, v| r += v.to_i } )
  end
end

class ToRedisHash < MapRedus::Finalizer
  def self.finalize(process)
    process.each_key_reduced_value do |key, value|
      process.outputter.encode(process.keyname, key, value)
    end
  end
end
