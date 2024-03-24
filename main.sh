z='gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  /orgs/osomstudio/repos --paginate > repos.json 

cat repos.json | jq '.' > repos-pritified.json

jq ".[].full_name" -r repos-pritified.json > repo_urls.txt

cat repo_urls.txt | while read line || [[ -n $line ]];
do
	gh repo clone "$line"
done
'
#we somehow have to then add those blocks on a page or multiple pages based on all projects
#when we added those blocks we have to fill in their fields so that we display something
#we will have issues with blocks that need some posts so we might have to create a list of projects pulled
#so that we can fix some posts or other things manually
for entry in `ls -d */`
do
	entry=${entry%/*}
	small_entry=${entry,,}

	if [ -d "$entry/web/app/themes/juniper-theme/blocks" ] || [ -d "$entry/web/app/themes/osom-theme/blocks" ]; then
		theme=""
		if [ -d "$entry/web/app/themes/juniper-theme/blocks" ]; then
			theme="juniper-theme"
		elif [ -d "$entry/web/app/themes/osom-theme/blocks" ]; then
			theme="osom-theme"
		fi

		blocks=()

		#TODO: take out the target path to a variable and update it to the new path
		#TODO: create a list of blocks that were imported so that we can fix them manually if we want to and they won't get overriden or do some kind of versioning system

		cd "$entry/web/app/themes/$theme/blocks"
		for block in `ls -d */`
		do
			block=${block%/*}
			blocks+=($block)

			cp -r "$block" "/home/haven/Local Sites/reuse-yor-blocks/app/public/wp-content/themes/juniper-theme/blocks/$block--$small_entry"

			#TODO: it might be better to check if this or the above doesn't exists and if that happens skip the block and tell it was skipped in a separate path
			# copy the twig file if it exists
			if [ -f "../views/blocks/$block.twig" ]; then
				echo "copying $block.twig"
				cp "../views/blocks/$block.twig" "/home/haven/Local Sites/reuse-yor-blocks/app/public/wp-content/themes/juniper-theme/views/blocks/$block--$small_entry.twig"
			fi


			# has_block
			#FUTURE INFO: we probably should check if the file has any require or include statements and if it does we should get them and update them
			# maybe there exists a way where we could require those files those file and merge them with the functions.php file so that we don't have multiple files
			sed -Ei "s|acf/$block|acf/$block--$small_entry|g" "/home/haven/Local Sites/reuse-yor-blocks/app/public/wp-content/themes/juniper-theme/blocks/$block--$small_entry/functions.php"

			# context
			sed -Ei "s|timber/acf-gutenberg-blocks-data/$block|timber/acf-gutenberg-blocks-data/$block--$small_entry|g" "/home/haven/Local Sites/reuse-yor-blocks/app/public/wp-content/themes/juniper-theme/blocks/$block--$small_entry/functions.php"

			#enqueue style & script
			sed -Ei "s|dist/blocks/$block|dist/blocks/$block--$small_entry|g" "/home/haven/Local Sites/reuse-yor-blocks/app/public/wp-content/themes/juniper-theme/blocks/$block--$small_entry/functions.php"

			# how do we work with CSS and JS files? in some projects we compile file by file but in others we have one fle
			# I'm going to asume this is one of those projects where we go file by file but we need to
			#TODO: create some kind of backup for blocks that aren't compiled properly
			#TODO: import global scss files like typography, mixins, variables project by project and update import paths in the blocks this way we should be able to split everything
		done

		cd "../acf-json"
		for acf in `ls`
		do
			acf=${acf%/*}
			for block in "${blocks[@]}"
			do
				sed -Ei "s|\"acf\\\/$block\"|\"acf\\\/$block--$small_entry\"|" $acf
			done
			cp "$acf" "/home/haven/Local Sites/reuse-yor-blocks/app/public/wp-content/themes/juniper-theme/acf-json/$acf"
		done

		#TODO: using wp cli import the acf json files - from what I remember we should be able to send a wget/curl request and do it
		#TODO: using wp cli or something like that automatically add the blocks to the page - one page one project and then one page with all of the blocks
		
		rm -rf $entry
	else
		echo "$entry does not have blocks"
		rm -rf $entry
	fi
done
