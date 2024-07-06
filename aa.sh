forge script script/AAScript.s.sol:AAScript  --rpc-url http://3.236.195.117:8998/ --broadcast -vvvv
//

SELECT ss.* 
FROM hd_user_relationship ur 
left join stats_user_staking ss on (ur.sub_user_address=ss.user_address)  
`stats_user_staking` 
WHERE ur.user_address="0x4507539A65290b1D7D378B3425A170179242A003" and ur.level_gap = 1


SELECT ss.* FROM 
hd_user_relationship ur 
inner join stats_user_staking ss on (ur.sub_user_address=ss.user_address)  
WHERE ur.user_address="0x4507539A65290b1D7D378B3425A170179242A003" and ss.node_role >0


SELECT ss.* FROM 
hd_user_relationship ur 
inner join hd_deposit_log ss on (ur.sub_user_address=ss.user_address)  
WHERE ur.user_address="0x4507539A65290b1D7D378B3425A170179242A003" and ss.created_at > '2024-07-05 00:00:00'