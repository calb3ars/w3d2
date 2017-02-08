Dir['./*.rb'].each { |file| require file }

class User
  attr_accessor :fname, :lname
  attr_reader :id

  def self.all
    data = QuestionsDB.instance.execute(<<-SQL)
      SELECT
        *
      FROM
        users
    SQL
    data.map { |datum| self.new(datum) }
  end

  def self.find_by_id(id)
    data = QuestionsDB.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL
    self.new(data.first)
  end

  def self.find_by_name(fname, lname)
    users = QuestionsDB.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users
      WHERE
        fname LIKE ? AND lname LIKE ?
    SQL
    users.map { |user| self.new(user) }
  end

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def authored_questions
    Question.find_by_author_id(@id)
  end

  def authored_replies
    Reply.find_by_user_id(@id)
  end

  def followed_questions
    Follow.followed_questions_for_user_id(@id)
  end

  def liked_questions
    Like.liked_questions_for_user_id(@id)
  end

  def average_karma
    result = QuestionsDB.instance.execute(<<-SQL, @id)
      SELECT
        (num_likes.total_likes / CAST(num_questions.total_questions AS FLOAT)) AS avg_likes
      FROM (
        SELECT
          author_id,
          COUNT(*) AS total_likes
        FROM
          questions
        LEFT OUTER JOIN
          likes ON questions.id = likes.question_id
        WHERE
          likes.id IS NOT NULL
        GROUP BY
          author_id) AS num_likes
      JOIN (
        SELECT
          author_id,
          COUNT(*) AS total_questions
        FROM
          questions
        GROUP BY
          author_id) AS num_questions
      ON num_likes.author_id = num_questions.author_id
      WHERE
        num_likes.author_id = ?
    SQL

    result.first['avg_likes']
  end

  def to_s
    "#{@fname} #{@lname}"
  end

  def save
    @id ? update : create
  end

  private

  def create
    raise "#{to_s} already exists in database" if @id
    QuestionsDB.instance.execute(<<-SQL, @fname, @lname)
      INSERT INTO
        users (fname, lname)
      VALUES
        (?, ?)
    SQL
    @id = QuestionsDB.instance.last_insert_row_id
  end

  def update
    raise "#{to_s} doesn't exist in database" unless @id
    QuestionsDB.instance.execute(<<-SQL, @fname, @lname, @id)
      UPDATE
        users
      SET
        fname = ?, lname = ?
      WHERE
        id = ?
    SQL
    nil
  end
end
