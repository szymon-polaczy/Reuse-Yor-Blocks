:'gh api \
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

	if [ -d "$entry/web/app/themes/juniper-theme/blocks" ] || [ -d "$entry/web/app/themes/osom-theme/blocks" ]; then
		theme=""
		if [ -d "$entry/web/app/themes/juniper-theme/blocks" ]; then
			theme="juniper-theme"
		elif [ -d "$entry/web/app/themes/osom-theme/blocks" ]; then
			theme="osom-theme"
		fi

		echo $theme

		# we have the blocks so we can move them to the new site
		# change the name to block--project_slug
		# this has to know if we are using osom or juniper theme

		cd "$entry/web/app/themes/$theme/blocks"
		for block in `ls -d */`
		do
			block=${block%/*}
			cp -r "$block" "/home/haven/Local Sites/reuse-yor-blocks/app/public/wp-content/themes/juniper-theme/blocks/$block--$entry"

			# so we have the block folder but we need the timber view file if it exists - we also have to sed
			# the name in the functions.php, js, css, and timber if needed so that we can use the block
			# project by project
		done

		cd "../acf-fields"
		for acf in `ls -d */`
		do
			echo $acf
			sed -i "s/\"value\":\"acf\/$block_name\"/\"value\":\"acf\/$block_name--$entry\"/g" $acf
			cp "$acf" "/home/haven/Local Sites/reuse-yor-blocks/app/public/wp-content/themes/juniper-theme/acf-fields/$acf"
		done
		
		# we don't have the blocks so we can remove the project
		#rm -rf $entry
	else
		echo "$entry does not have blocks"
		# we don't have the blocks so we can remove the project
		#rm -rf $entry
	fi
done

