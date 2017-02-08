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

  def self.followers_for_question_id(question_id)
    users = QuestionsDB.instance.execute(<<-SQL, question_id)
      SELECT
        users.*
      FROM
        users
      JOIN
        question_followers ON users.id = question_followers.follower_id
      WHERE
        question_id = ?
    SQL
    users.map { |user| User.new(user) }
  end

  def self.followed_questions_for_user_id(user_id)
    questions = QuestionsDB.instance.execute(<<-SQL, user_id)
      SELECT
        questions.*
      FROM
        questions
      JOIN
        question_followers ON questions.id = question_followers.question_id
      WHERE
        question_followers.follower_id = ?
    SQL
    questions.map { |question| Question.new(question) }
  end

  def self.most_followed_questions(n)
    questions = QuestionsDB.instance.execute(<<-SQL, n)
    SELECT
      questions.*
    FROM
      questions
    JOIN
      question_followers ON questions.id = question_followers.question_id
    GROUP BY
      question_followers.question_id
    ORDER BY
      COUNT(question_followers.follower_id) DESC
    LIMIT ?
    SQL
    questions.map { |question| Question.new(question) }
  end

  def initialize(options)
    @id = options['id']
    @follower_id = options['follower_id']
    @question_id = options['question_id']
  end

  def save
    @id ? update : create
  end

  def to_s
    "#{User.find_by_id(@follower_id).fname.blue} follows #{Question.find_by_id(@question_id).title.red}"
  end

  private

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

end
