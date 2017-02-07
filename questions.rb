Dir['./*.rb'].each { |file| require file }

require 'colorize'


class Question
  attr_accessor :body, :author_id, :title
  attr_reader :id

  def self.all
    data = QuestionsDB.instance.execute(<<-SQL)
      SELECT
        *
      FROM
        questions
    SQL
    data.map { |datum| self.new(datum) }
  end

  def self.find_by_id(id)
    data = QuestionsDB.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        questions
      WHERE
        id = ?
    SQL
    self.new(data.first)
  end

  def self.find_by_author_id(author_id)
    questions = QuestionsDB.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        questions
      WHERE
        author_id = ?
    SQL
    questions.map{ |question| self.new(question) }
  end

  def initialize(options)
    @id = options['id']
    @author_id = options['author_id']
    @title = options['title']
    @body = options['body']
  end

  def create
    raise "#{@title} has been asked already" if @id
    QuestionsDB.instance.execute(<<-SQL, @author_id, @title, @body)
      INSERT INTO
        questions (author_id, title, body)
      VALUES
        (?, ?, ?)
    SQL
    @id = QuestionsDB.instance.last_insert_row_id
  end

  def update
    raise "#{@title} hasn't been asked" unless @id
    QuestionsDB.instance.execute(<<-SQL, @author_id, @title, @body, @id)
      UPDATE
        questions
      SET
        author_id = ?, title = ?, body = ?
      WHERE
        id = ?
    SQL
    nil
  end

  def author
    User.find_by_id(@author_id)
  end

  def replies
    Reply.find_by_question_id(@id)
  end

  def to_s
    "#{User.find_by_id(@author_id).fname.blue} asked: #{@title.red}\n#{@body.green}"
  end
end
