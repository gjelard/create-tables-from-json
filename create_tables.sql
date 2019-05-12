DELIMITER ;;
CREATE PROCEDURE `create_tables` (INOUT `_json` json)
BEGIN
    -- set local variables;
    SET @counter = 0,
        @name = '',
        @body = '',
        @type = '',
        @comment = '';
   -- set incoming json parameters
   SET @_name = JSON_EXTRACT(_json, '$._name');
   SET @_id = JSON_EXTRACT(_json, '$._id');


  -- set json for return status:: 0[good], 1[warning], 2[error]
  -- SET _json = '{ "status": 1, "message": "procedure did not run"}';
     SET _json = JSON_MERGE_PATCH(_json, '{ "status": 1, "message": "procedure did not run"}');

  -- select from any table (body must be JSON data type)
  SELECT name, body, type, comment INTO @name, @body, @type, @comment FROM tables WHERE id = @_id OR name = @_name LIMIT 1;

IF @name != '' THEN

    SELECT COUNT(1) INTO @table_exists
    FROM information_schema.tables
    WHERE table_schema=DATABASE()
    AND table_name = @name;

IF @table_exists = 0 THEN

  -- add column(s) 1st
  SET @columns = JSON_EXTRACT(@body, '$.columns');

 -- check if the columns are formated correctly
 IF JSON_TYPE(@columns) = 'ARRAY' THEN
  -- add each column one by one
  WHILE @counter < JSON_LENGTH(@columns) DO
    SET @trim = TRIM(BOTH '"' FROM JSON_EXTRACT(@columns, CONCAT('$[',@counter,']')));
    SET @sql = CONCAT_WS(',',@sql,@trim);
    SET @counter = @counter + 1;
  END WHILE;
 END IF;

  -- add references 2nd
  SET @counter = 0;
  SET @references = JSON_EXTRACT(@body, '$.references');
  IF JSON_TYPE(@references) = 'ARRAY' THEN
  WHILE @counter < JSON_LENGTH(@references) DO
    -- SET @r = REPLACE(JSON_EXTRACT(@references, CONCAT('$[',@counter,']')), '"', '');
    SET @trim = TRIM(BOTH '"' FROM JSON_EXTRACT(@references, CONCAT('$[',@counter,']')));
    SET @sql = CONCAT_WS(',',@sql,@trim);

    SET @counter = @counter + 1;
  END WHILE;
  END IF;

-- add table settings 3rd
   SET @sql = CONCAT('CREATE TABLE IF NOT EXISTS ',@name,' (',@sql,')');
   SET @sql = CONCAT(@sql,' ','ENGINE = INNODB');
   SET @sql = CONCAT(@sql,' ',' DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci');
   SET @sql = CONCAT(@sql,' ',' COMMENT ="',@comment,'"');

-- prepare and execute table
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE s;
   SET _json = '{ "status": 0, "message": "procedure completed"}';
ELSE
   SET _json = JSON_REPLACE(_json, '$.status', 1, '$.message', 'table already exists');
END IF; -- @table_exists = 0
ELSE
   SET _json = JSON_REPLACE(_json, '$.status', 2, '$.message', 'missing table name or it does not exist');
END IF; -- @name != ''


END;;
DELIMITER ;
