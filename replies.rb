Dir['./*.rb'].each { |file| require file }

require 'colorize'


class Reply
  attr_accessor :question_id, :user_id, :parent_id, :body
  attr_reader :id

  def self.all
    data = QuestionsDB.instance.execute(<<-SQL)
      SELECT
        *
      FROM
        replies
    SQL
    data.map { |datum| self.new(datum) }
  end

  def self.find_by_id(id)
    data = QuestionsDB.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        id = ?
    SQL
    self.new(data.first)
  end

  def self.find_by_user_id(user_id)
    replies = QuestionsDB.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        replies
      WHERE
        user_id = ?
    SQL
    replies.map { |reply| self.new(reply) }
  end

  def self.find_by_question_id(question_id)
    replies = QuestionsDB.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        replies
      WHERE
        question_id = ?
    SQL
    replies.map { |reply| self.new(reply) }
  end

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @user_id = options['user_id']
    @parent_id = options['parent_id']
    @body = options['body']
  end

  def author
    User.find_by_id(@user_id)
  end

  def question
    Question.find_by_id(@question_id)
  end

  def parent_reply
    return nil unless @parent_id
    Reply.find_by_id(@parent_id)
  end

  def child_replies
    replies = QuestionsDB.instance.execute(<<-SQL, @id)
      SELECT
        *
      FROM
        replies
      WHERE
        parent_id = ?
    SQL
    replies.map { |reply| Reply.new(reply)}
  end

  def to_s
    "#{User.find_by_id(@user_id).fname.blue} replied to #{Question.find_by_id(@question_id).title.red}\n
    #{@body}"
  end

  def save
    @id ? update : create
  end

  private

  def create
    raise "This reply already exists" if @id
    QuestionsDB.instance.execute(<<-SQL, @question_id, @user_id, @parent_id, @body)
      INSERT INTO
        replies (question_id, user_id, parent_id, body)
      VALUES
        (?, ?, ?, ?)
    SQL
    @id = QuestionsDB.instance.last_insert_row_id
  end

  def update
    raise "This reply doesn't exist yet" unless @id
    QuestionsDB.instance.execute(<<-SQL, @question_id, @user_id, @parent_id, @body, @id)
      UPDATE
        replies
      SET
        question_id = ?, user_id = ?, parent_id = ?, body = ?
      WHERE
        id = ?
    SQL
    nil
  end
end
