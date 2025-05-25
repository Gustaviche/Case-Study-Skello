use `skello_case`;


SELECT DISTINCT 
       c.id as conversation_id,
       c.created_at,
       cp.notified_at,
       c.updated_at,
       c.assignee_id,
       cr.rating,
       cr.remark,
       a.type,
       a.id
FROM conversations c
INNER JOIN conversation_parts cp ON cp.conversation_id = c.id 
INNER JOIN author a ON a.id = cp.author_id
INNER JOIN conversation_ratings cr ON cr.conversation_id = c.id
WHERE a.type != 'bot'
INTO OUTFILE '/Users/algaumon/Documents/Case Study Skello/kpi/conv.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n';


#temps de première réponse
SELECT 
    c.id AS conversation_id,
    MIN(CASE WHEN a.type = 'user' THEN cp.created_at END) AS user_first_message,
    MIN(CASE WHEN a.type = 'admin' THEN cp.created_at END) AS admin_first_reply,
    TIMESTAMPDIFF(MINUTE, 
        MIN(CASE WHEN a.type = 'user' THEN cp.created_at END),
        MIN(CASE WHEN a.type = 'admin' THEN cp.created_at END)
    ) AS first_response_time_minutes
FROM conversations c
JOIN conversation_parts cp ON cp.conversation_id = c.id
JOIN author a ON a.id = cp.author_id
WHERE a.type IN ('user', 'admin')
GROUP BY c.id
HAVING 
    user_first_message IS NOT NULL
    AND admin_first_reply IS NOT NULL
    AND user_first_message < admin_first_reply;


#CSAT
SELECT
    COUNT(*) AS total_rated,
    SUM(CASE WHEN rating >= 4 THEN 1 ELSE 0 END) AS satisfied_count,
    ROUND(100.0 * SUM(CASE WHEN rating >= 4 THEN 1 ELSE 0 END) / COUNT(*), 2) AS csat_percentage
FROM conversation_ratings
WHERE rating IS NOT NULL;

#reponse moins de 5 minutes
SELECT
    COUNT(*) AS total_conversations,
    SUM(CASE WHEN TIMESTAMPDIFF(MINUTE, user_first_message, admin_first_reply) <= 5 THEN 1 ELSE 0 END) AS responded_under_5min,
    ROUND(100.0 * SUM(CASE WHEN TIMESTAMPDIFF(MINUTE, user_first_message, admin_first_reply) <= 5 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_responded_under_5min
FROM (
    SELECT 
        c.id AS conversation_id,
        MIN(CASE WHEN a.type = 'user' THEN cp.created_at END) AS user_first_message,
        MIN(CASE WHEN a.type = 'admin' THEN cp.created_at END) AS admin_first_reply
    FROM conversations c
    JOIN conversation_parts cp ON cp.conversation_id = c.id
    JOIN author a ON a.id = cp.author_id
    WHERE a.type IN ('user', 'admin')
    GROUP BY c.id
    HAVING user_first_message IS NOT NULL 
       AND admin_first_reply IS NOT NULL 
       AND user_first_message < admin_first_reply
) AS first_messages;


#moment les plus remplis
SELECT 
    DAYNAME(cp.created_at) AS day_of_week,
    HOUR(cp.created_at) AS hour_of_day,
    COUNT(*) AS message_count
FROM conversation_parts cp
JOIN author a ON a.id = cp.author_id
WHERE a.type != 'bot'
GROUP BY day_of_week, hour_of_day
ORDER BY 
    FIELD(day_of_week, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
    hour_of_day;

#nb messsages par admin
SELECT 
    a.id AS agent_id,
    a.type AS agent_name,
    COUNT(*) AS nb_messages
FROM conversation_parts cp
JOIN author a ON a.id = cp.author_id
WHERE a.type = 'admin'
GROUP BY a.id, a.type
ORDER BY nb_messages DESC;


SHOW VARIABLES LIKE 'secure_file_priv';

SELECT VERSION();