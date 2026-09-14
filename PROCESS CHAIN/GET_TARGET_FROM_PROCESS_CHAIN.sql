create or replace procedure GET_TARGET_FROM_PROCESS_CHAIN(
	in i__chain nvarchar(40), in i__type nvarchar(20)
)
language sqlscript sql security invoker as begin
	_DataTransferProcess = 
		select 	variante
		from SAPHANADB.RSPCCHAIN
		where
				chain_id = :i__chain and
				type = :i__type and
				objvers	= 'A';
	_ADSOTargets =
		select	dtp,
				src	    source,
				srctp 	srctp,
				tgt 	target,
				tgttp 	tgttp
		from SAPHANADB.RSBKDTP where objvers = 'A';
		
	_ADSOAttributes = 
		select  adsonm,
				activate_data,
				write_changelog,
				unique_records,
				direct_update,
				cubedeltaonly
		from SAPHANADB.RSOADSO where objvers = 'A';
	
	var_out = 
		select 	a.variante  dtp,
				b.target	adso,
				case
					when c.activate_data = '' 	and c.direct_update = '' 	then 'Staging'
					when c.activate_data = 'X' 	and c.cubedeltaonly = 'X'	then 'DataMart'
					when c.direct_update = 'X'								then 'DirectUpdate'
					else 'Standard'
				end                                 adso_type,
				coalesce(c.activate_data, '')		activate_data,
				coalesce(c.write_changelog, '')	    write_changelog,
				coalesce(c.unique_records, '')		unique_records,
				coalesce(c.direct_update, '')		direct_update,
				coalesce(c.cubedeltaonly, '')		cubedeltaonly
		from :_DataTransferProcess a
		left join :_ADSOTargets b 	    on a.variante = b.dtp
		left join :_ADSOAttributes c 	on b.target = c.adsonm;
	
	select * from :var_out;
end;

call GET_TARGET_FROM_PROCESS_CHAIN( <process_chain_id>, 'DTP_LOAD' );


--*------------------------------------------------------------------------------------
--* This is an sql procedure to get the adso that are loaded with the dtps in a process
--* chain.
--*------------------------------------------------------------------------------------