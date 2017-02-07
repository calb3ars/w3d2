Dir['./*.rb'].each { |file| require file }

require 'colorize'

class Follow
  attr_accessor :follower_id, :question_id
  attr_reader :id

  def self.all
    data = QuestionsDB.instance.execute(<<-SQL)
      SELECT
        *
      FROM
        question_followers
    SQL
    data.map { |datum| self.new(datum) }
  end

  def self.find_by_id(id)
    data = QuestionsDB.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_followers
      WHERE
        id = ?
    SQL
    self.new(data.first)
  end

  def initialize(options)
    @id = options['id']
    @follower_id = options['follower_id']
    @question_id = options['question_id']
  end

  def create
    raise "This follow already exists" if @id
    QuestionsDB.instance.execute(<<-SQL, @follower_id, @question_id)
      INSERT INTO
        question_followers (follower_id, question_id)
      VALUES
        (?, ?)
    SQL
    @id = QuestionsDB.instance.last_insert_row_id
  end

  def update
    raise "This follow doesn't exist yet" unless @id
    QuestionsDB.instance.execute(<<-SQL, @follower_id, @question_id, @id)
      UPDATE
        question_followers
      SET
        follower_id = ?, question_id = ?
      WHERE
        id = ?
    SQL
    nil
  end

  def to_s
    "#{User.find_by_id(@follower_id).fname.blue} follows #{Question.find_by_id(@question_id).title.red}"
  end
end
