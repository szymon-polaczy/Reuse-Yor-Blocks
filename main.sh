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

		# we have the blocks so we can move them to the new site
		# change the name to block--project_slug
		# this has to know if we are using osom or juniper theme
		cd "$entry/web/app/themes/$theme/blocks"
		for block in `ls -d */`
		do
			block=${block%/*}
			blocks+=($block)

			cp -r "$block" "/home/haven/Local Sites/reuse-yor-blocks/app/public/wp-content/themes/juniper-theme/blocks/$block--$small_entry"

			# copy the twig file if it exists
			if [ -f "../views/blocks/$block.twig" ]; then
				echo "copying $block.twig"
				cp "../views/blocks/$block.twig" "/home/haven/Local Sites/reuse-yor-blocks/app/public/wp-content/themes/juniper-theme/views/blocks/$block--$small_entry.twig"
			fi


			# has_block
			sed -Ei "s|acf/$block|acf/$block--$small_entry|g" "/home/haven/Local Sites/reuse-yor-blocks/app/public/wp-content/themes/juniper-theme/blocks/$block--$small_entry/functions.php"

			# context
			sed -Ei "s|timber/acf-gutenberg-blocks-data/$block|timber/acf-gutenberg-blocks-data/$block--$small_entry|g" "/home/haven/Local Sites/reuse-yor-blocks/app/public/wp-content/themes/juniper-theme/blocks/$block--$small_entry/functions.php"

			#enqueue style & script
			sed -Ei "s|dist/blocks/$block|dist/blocks/$block--$small_entry|g" "/home/haven/Local Sites/reuse-yor-blocks/app/public/wp-content/themes/juniper-theme/blocks/$block--$small_entry/functions.php"

			# we also have to sed
			# the name in the js, css, and if needed so that we can use the block
			# project by project

			# how do we work with CSS and JS files? in some projects we compile file by file but in others we have one fle
			
			#what do we also do about some "typography" "mixins" "variables" etc
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
		
		rm -rf $entry
	else
		echo "$entry does not have blocks"
		rm -rf $entry
	fi
done
