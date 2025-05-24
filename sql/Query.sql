use `skello-case`;

select distinct 
	   c.id as conversation_id
	  ,c.created_at
	  ,c.updated_at
	  ,c.assignee_id
	  ,cr.rating
	  ,cr.remark
	  ,a.type
	  ,a.id
from conversations c
inner join conversation_parts cp on cp.conversation_id = c.id 
inner join author a on a.id = cp.author_id
inner join conversation_ratings cr on cr.conversation_id = c.id
where a.type = 'user';
