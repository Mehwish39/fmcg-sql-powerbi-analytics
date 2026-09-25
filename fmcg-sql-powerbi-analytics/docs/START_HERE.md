# Your step-by-step learning guide

Work through one checkpoint at a time. You do not need to complete this entire guide today.

## Step 1 — Prepare the files (do this now)

1. Extract FMCG_ERP_Portfolio.zip using Windows Extract All.
2. Move the extracted FMCG_ERP_Portfolio folder to a convenient location such as Documents. Keep the folder structure.
3. Open data and confirm there are seven CSV files. Do not resave them through Excel; use the originals for importing.
4. Read the repository README for the company brief and questions.
5. Open SSMS and connect to your Database Engine as you normally do. SSMS is the management application; a running SQL Server instance is also required.
6. Open sql/00_check_environment.sql, select Execute, and note the version and edition result.
7. Tell your assistant whether connection succeeded and the SQL Server version/edition. Do not send passwords or connection secrets. If connection fails, share the error text.

Stop here for the first session. The next import instructions will match your SQL Server version and local file location.

## Step 2 — Import and profile (next guided session)

Create a dedicated database, import the seven CSV files into raw staging tables, and match row counts to DATA_MANIFEST.json. Establish typed clean tables/views using the dictionary. The raw layer keeps source strings; clean transformations handle whitespace, NULLs and types. SQL Server reads import paths on its own host, and its service identity needs access; a file visible to SSMS is not automatically visible to the server. We will select a suitable import method after the environment check.

Save scripts in sql in execution order: 01_create_database, 02_import, 03_profile, 04_clean, 05_validate. Capture rejected conversions instead of silently dropping rows. Validate primary keys, references, ranges and daily inventory balances.

## Step 3 — Answer the questions in SQL

Work through MANAGEMENT_QUESTIONS.md one question at a time. Save ten numbered analysis scripts. Learn CTEs, joins at the right grain, conditional aggregation, window functions and date logic through these questions. Save the numerical findings with the filters and cutoff used. Aggregate child rows before joining when needed to prevent duplication.

## Step 4 — Build the Power BI model

Use Get data > SQL Server and Import mode. Load prepared fact and dimension views. Follow BUSINESS_RULES.md for the model, then make explicit DAX measures. Start with net invoiced sales, credits, net sales, COGS, gross profit and margin. Add service, stock, production and supplier measures only after their SQL versions reconcile.

## Step 5 — Build and verify the report

Create four report pages: Executive Overview; Sales and Customers; Supply and Service; Manufacturing and Suppliers. Use clear titles, consistent GBP formatting, readable labels, date filters, drill-through and useful tooltips. Show the data cutoff. Check totals under at least one year, one SKU and one region against SQL. Save the PBIX, model screenshot, report screenshots and DAX documentation.

## Step 6 — Create your GitHub repository

1. Sign in to GitHub. Select + > New repository.
2. Use the name fmcg-sql-powerbi-analytics and a short project description.
3. Choose Public if ready to show work in progress. Otherwise use Private until your analysis is ready.
4. Leave automatic README, .gitignore and license creation unselected; the package already has a README.
5. Click Create repository, then select the link to upload existing files.
6. Drag README.md and the data, docs, sql, powerbi, screenshots and scripts folders from INSIDE the extracted project folder into the upload area. Upload small batches if necessary. The repository root should contain README.md, not an extra enclosing folder or just a ZIP.
7. Enter the commit message `Add synthetic FMCG dataset and project brief`, then commit.
8. Check that README renders and the seven files appear under data. You can begin with README/docs and upload data in a second commit.
9. As you finish each learning phase, use Add file > Upload files to upload the changed files to their correct folder. Describe what changed in a short commit message, such as `Add SQL data quality checks`.
10. Before adding Power BI files, inspect file sizes. Browser uploads are limited to 25 MiB per file. If the PBIX exceeds the limit, add screenshots and a report link first; use a GitHub Release for the PBIX or a Git LFS workflow in a later guided step. Do not repeatedly upload an oversized file.
11. Replace the README's pending section with your verified findings. For each, give the metric, date scope, proposed action and a limitation. Never claim a simulated recommendation generated real company savings.
12. Add a report link and screenshots, and document how to reproduce SQL import and model refresh. Include tool versions and data cutoff. If you chose Private, switch visibility to Public when you are ready.
13. In repository About, add a description, the working report URL and topics such as sql-server, power-bi, dax, fmcg and data-analysis. Pin the repository on your profile.

The README scaffold is deliberately honest about work in progress. Update it as you complete the analysis. Keep real credentials, private connection strings and unrelated personal files out of the repository. Browser uploads do not honor local .gitignore rules automatically.

Official references: [Create a repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-new-repository) and [Upload files and limits](https://docs.github.com/en/repositories/working-with-files/managing-files/adding-a-file-to-a-repository).

## Step 7 — Publish to Power BI Service

1. Finish and save the Desktop report using Import mode. Check that the model contains only this synthetic project data.
2. Sign in to Power BI and publish the PBIX to a workspace available to your account.
3. Open the published report and verify visuals and filters. Publishing alone does not create a public recruiter link.
4. For public viewing, check File > Embed report > Publish to web (public). This needs a Power BI license and an enabled tenant setting; other workspaces require Pro or Premium Per User. Availability depends on the account and tenant.
5. Publish to web exposes the report and underlying model data publicly. This synthetic dataset is designed for that purpose. Review the prompt before creating the public link.
6. Test the generated URL in a signed-out/private browser window. Add that tested link to GitHub. GitHub README does not host a live Power BI iframe; use a screenshot that links to the report.
7. If Publish to web is unavailable, publish screenshots and a PDF export on GitHub while resolving account/tenant access. A normal workspace link may require recruiter sign-in and permissions.
8. This is a fixed dataset: an initial imported report does not need your laptop running to be viewed. Refreshing from local SQL Server later requires a configured gateway and available data source. We will handle refresh separately if you extend the project.

Reference: [Microsoft Publish to web prerequisites and instructions](https://learn.microsoft.com/en-us/power-bi/collaborate-share/service-publish-to-web). Account and licensing requirements can change; verify again when publishing.

## Step 8 — Prepare to discuss the work

Explain one business problem, show the model, demonstrate a difficult SQL query, explain one DAX measure, and defend one recommendation. Be ready to describe grain, double counting, NULL handling, date roles, inventory snapshots, cohort bias and the simulation's limitations. These explanations provide stronger evidence than dashboard appearance alone.
