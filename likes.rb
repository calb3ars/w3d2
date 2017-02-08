Dir['./*.rb'].each { |file| require file }

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

  def self.likers_for_question_id(question_id)
    users = QuestionsDB.instance.execute(<<-SQL, question_id)
      SELECT
        users.*
      FROM
        users
      JOIN likes
        ON users.id = likes.user_id
      WHERE
        likes.question_id = ?
    SQL

    users.map { |user| User.new(user) }
  end

  def self.num_likes_for_question_id(question_id)
    result = QuestionsDB.instance.execute(<<-SQL, question_id)
      SELECT
        COUNT(*) AS total
      FROM
        likes
      WHERE
        likes.question_id = ?
    SQL

    result.first['total']
  end

  def self.liked_questions_for_user_id(user_id)
    questions = QuestionsDB.instance.execute(<<-SQL, user_id)
      SELECT
        questions.*
      FROM
        likes
      JOIN
        questions ON likes.question_id = questions.id
      JOIN
        users ON likes.user_id = users.id
      WHERE
        users.id = ?
    SQL

    questions.map { |question| Question.new(question) }
  end

  def self.most_liked_questions(n)
    questions = QuestionsDB.instance.execute(<<-SQL, n)
    SELECT
      questions.*
    FROM
      questions
    JOIN
      likes ON questions.id = likes.question_id
    GROUP BY
      likes.question_id
    ORDER BY
      COUNT(likes.user_id) DESC
    LIMIT ?
    SQL
    questions.map { |question| Question.new(question) }
  end

  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end

  def to_s
    "#{User.find_by_id(@user_id).fname.blue} likes question #{Question.find_by_id(@question_id).title.red}"
  end

  def save
    @id ? update : create
  end

  private

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
end
