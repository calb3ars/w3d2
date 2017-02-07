require_relative 'questionsdb'
require_relative 'users'
require_relative 'questions'
require 'colorize'


class Like
  attr_accessor :user_id, :question_id
  attr_reader :id

  def self.all
    data = QuestionsDB.instance.execute(<<-SQL)
      SELECT
        *
      FROM
        likes
    SQL
    data.map { |datum| self.new(datum) }
  end

  def self.find_by_id(id)
    data = QuestionsDB.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        likes
      WHERE
        id = ?
    SQL
    self.new(data.first)
  end

  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end

  def create
    raise "This like already exists" if @id
    QuestionsDB.instance.execute(<<-SQL, @user_id, @question_id)
      INSERT INTO
        likes (user_id, question_id)
      VALUES
        (?, ?)
    SQL
    @id = QuestionsDB.instance.last_insert_row_id
  end

  def update
    raise "This like doesn't exist yet" unless @id
    QuestionsDB.instance.execute(<<-SQL, @user_id, @question_id, @id)
      UPDATE
        likes
      SET
        user_id = ?, question_id = ?
      WHERE
        id = ?
    SQL
    nil
  end

  def to_s
    "#{User.find_by_id(@user_id).fname.blue} likes question #{Question.find_by_id(@question_id).title.red}"
  end
end
