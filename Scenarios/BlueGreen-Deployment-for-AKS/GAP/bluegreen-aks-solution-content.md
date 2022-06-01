> The H1 title is a noun phrase that describes the scenario. Don't enter it here, but as the **name** value in the corresponding YAML file.

What happen when you need to upgrade the kubernetes version in a cluster or even better when you need to change kubernetes platform components like: ingress gateway, service mesh, operators and so on, but you don't want to have impact on the workloads/applications that are running on the cluster itself?
The answer that will make all happy from infra to apps is blue green deployment at Kubernetes infra level.
With modern principles and availability of cloud services like:
- [IaC](https://docs.microsoft.com/en-us/devops/deliver/what-is-infrastructure-as-code)
- [Immutable Infrastructure](https://www.hashicorp.com/resources/what-is-mutable-vs-immutable-infrastructure)
- [Cloud Elasticity](https://azure.microsoft.com/en-us/overview/what-is-elastic-computing/)
- [Continuous Delivery](https://docs.microsoft.com/en-us/devops/deliver/what-is-continuous-delivery)

Blue Green deployment is become a de-facto standard pattern for the release management and operation at infra and application level in kubernetes environments.
In this article is described the design and implementaation of the blue green deployment for AKS laveraging Azure Cloud managed services and native kuberneetes features. With the adoption of this pattern improve the reliability and availability during the deployment of changes/upgrade of AKS clusters.
The main benefits of the solution are:
- Minimized downtime during the release
- Rollback strategy out of the box
- Improved control during the release and deployment of AKS changes and upgrades
- Test for DR procedure

The Azure services that are part of the pattern are:
- AKS
- Azure Application Gateway
- Azure Private DNS

From an automation and CI/CD perspective the solution can be implemented in multiple ways, our suggestions are:
- Bicep or Terraform  for the IaC
- Azure Pipelines or Github Actions for the CI/CD


> This should be an introduction of the business problem and why this scenario was built to solve it.
>> What prompted them to solve the problem?
>> What services were used in building out this solution?
>> What does this example scenario show? What are the customer's goals?

> What were the benefits of implementing the solution described below?

## Potential use cases

> What industry is the customer in? 
> Are there any other use cases or industries where this would be a fit?
> How similar or different are they to what's in this article?

> Because this is a generalized architecture pattern, use the following language to link to the other architectures (likely solution ideas) that build off of it, as shown below.

This solution is a generalized architecture pattern, which can be used for many different scenarios and industries; in particular can be applied in most of the AKS deployment and is also used for [Mission Critical scenario](https://docs.microsoft.com/en-us/azure/architecture/reference-architectures/containers/aks-multi-region/aks-multi-cluster) See the following example solutions that build off of this core architecture:

- [Link to first solution idea or other architecture that builds off this solution](filepath.yml)


## Architecture

> Architecture diagram goes here

> Under the architecture diagram, include this sentence and a link to the Visio file or the PowerPoint file: 

*Download a [Visio file](https://arch-center.azureedge.net/[filename].vsdx) of this architecture.*

### Dataflow

> An alternate title for this sub-section is "Workflow" (if data isn't really involved).
> In this section, include a numbered list that annotates/describes the dataflow or workflow through the solution. Explain what each step does. Start from the user or external data source, and then follow the flow through the rest of the solution (as shown in the diagram).

Examples:
1. Admin 1 adds, updates, or deletes an entry in Admin 1's fork of the Microsoft 365 config file.
2. Admin 1 commits and syncs the changes to Admin 1's forked repository.
3. Admin 1 creates a pull request (PR) to merge the changes to the main repository.
4. The build pipeline runs on the PR.

### Components

> A bullet list of components in the architecture (including all relevant Azure services) with links to the product service pages. This is for lead generation (what business, marketing, and PG want). It helps drive revenue.

> Why is each component there?
> What does it do and why was it necessary?
> Link the name of the service (via embedded link) to the service's product service page. Be sure to exclude the localization part of the URL (such as "en-US/").

- Examples: 
  - [Azure App Service](https://azure.microsoft.com/services/app-service)
  - [Azure Bot Service](https://azure.microsoft.com/services/bot-service)
  - [Azure Cognitive Services Language Understanding](https://azure.microsoft.com/services/cognitive-services/language-understanding-intelligent-service)
  - [Azure Cognitive Services Speech Services](https://azure.microsoft.com/services/cognitive-services/speech-services)
  - [Azure SQL Database](https://azure.microsoft.com/services/sql-database)
  - [Azure Monitor](https://azure.microsoft.com/services/monitor): Application Insights is a feature of Azure Monitor.
  - [Resource Groups][resource-groups] is a logical container for Azure resources.  We use resource groups to organize everything related to this project in the Azure console.

### Alternatives

> Use this section to talk about alternative Azure services or architectures that you might consider for this solution. Include the reasons why you might choose these alternatives. Customers find this valuable because they want to know what other services or technologies they can use as part of this architecture.

> What alternative technologies were considered and why didn't we use them?
> List all "children" architectures (likely solution ideas) that build off this GAP architecture

The following alternative solutions provide scenario-focused lenses to build off of this core architecture: 

- [Link to first solution idea or other architecture that builds off this solution](filepath.yml)
- [Second solution idea that builds off this solution](filepath.yml)

## Considerations

> Include a statement to introduce this section, like this:
> "These considerations implement the pillars of the Azure Well-Architected Framework, which is a set of guiding tenets that can be used to improve the quality of a workload. For more information, see [Microsoft Azure Well-Architected Framework](/azure/architecture/framework)."

> Are there any lessons learned from running this that would be helpful for new customers?  What went wrong when building it out?  What went right?
> How do I need to think about managing, maintaining, and monitoring this long term?
> REQUIREMENT: Note that you must have "Cost optimization" and at least two of the other H3 sub-sections/pillars.

### Reliability

> This includes resiliency and availability.
> Are there any key resiliency and reliability considerations (past the typical)?
> Include a link to the [Overview of the reliability pillar](/azure/architecture/framework/resiliency/overview).

### Security

> This includes identity and data sovereignty.
> Are there any security considerations (past the typical) that I should know about this? 
> Include a link to the [Overview of the operational excellence pillar](/azure/architecture/framework/devops/overview).

### Cost optimization

> REQUIRED: This section is required. Cost is of the utmost importance to our customers.

> How much will this cost to run? See if you can answer this without dollar amounts.
> Are there ways I could save cost?
> If it scales linearly, than we should break it down by cost/unit. If it does not, why?
> What are the components that make up the cost?
> How does scale affect the cost?
> Include a link to the [Overview of the cost optimization pillar](/azure/architecture/framework/cost/overview).

> Link to the pricing calculator with all of the components in the architecture included, even if they're a $0 or $1 usage.
> If it makes sense, include small/medium/large configurations. Describe what needs to be changed as you move to larger sizes.

### Operational excellence

> This includes DevOps, monitoring, and diagnostics.
> How do I need to think about operating this solution?
> Include a link to the [Overview of the operational excellence pillar](/azure/architecture/framework/devops/overview).

### Performance efficiency

> This includes scalability.
> Are there any key performance considerations (past the typical)?
> Are there any size considerations around this specific solution? What scale does this work at? At what point do things break or not make sense for this architecture?
> Include a link to the [Performance efficiency pillar overview](/azure/architecture/framework/scalability/overview).

## Deploy this scenario

> (Optional, but greatly encouraged)

> Is there an example deployment that can show me this in action?  What would I need to change to run this in production?

## Contributors

> (Expected, but this section is optional if all the contributors would prefer to not include it)

> Start with the explanation text (same for every section), in italics. This makes it clear that Microsoft takes responsibility for the article (not the one contributor). Then include the "Pricipal authors" list and the "Additional contributors" list (if there are additional contributors). Link each contributor's name to the person's LinkedIn profile. After the name, place a pipe symbol ("|") with spaces, and then enter the person's title. We don't include the person's company, MVP status, or links to additional profiles (to minimize edits/updates). (The profiles can be linked to from the person's LinkedIn page, and we hope to automate that on the platform in the future). 
> Implement this format:

*This article is maintained by Microsoft. It was originally written by the following contributors.*

**Principal authors:** > Only the primary authors. Listed alphabetically by last name. Use this format: Fname Lname. If the article gets rewritten, keep the original authors and add in the new one(s).

 * [Author 1 Name](http://linkedin.com/ProfileURL) | (Title, such as "Cloud Solution Architect")
 * [Author 2 Name](http://linkedin.com/ProfileURL) | (Title, such as "Cloud Solution Architect")
 * > Continue for each primary author (even if there are 10 of them).

**Other contributors:** > Include contributing (but not primary) authors, major editors (not minor edits), and technical reviewers. Listed alphabetically by last name. Use this format: Fname Lname. It's okay to add in newer contributors.

 * [Contributor 1 Name](http://linkedin.com/ProfileURL) | (Title, such as "Cloud Solution Architect")
 * [Contributor 2 Name](http://linkedin.com/ProfileURL) | (Title, such as "Cloud Solution Architect")
 * > Continue for each additional contributor (even if there are 10 of them).

## Next steps

> Link to Docs and Learn articles, along with any third-party documentation.
> Where should I go next if I want to start building this?
> Are there any relevant case studies or customers doing something similar?
> Is there any other documentation that might be useful? Are there product documents that go into more detail on specific technologies that are not already linked?

Examples:
* [Azure Kubernetes Service (AKS) documentation](/azure/aks)
* [Azure Machine Learning documentation](/azure/machine-learning)
* [What are Azure Cognitive Services?](/azure/cognitive-services/what-are-cognitive-services)
* [What is Language Understanding (LUIS)?](/azure/cognitive-services/luis/what-is-luis)
* [What is the Speech service?](/azure/cognitive-services/speech-service/overview)
* [What is Azure Active Directory B2C?](/azure/active-directory-b2c/overview)
* [Introduction to Bot Framework Composer](/composer/introduction)
* [What is Application Insights](/azure/azure-monitor/app/app-insights-overview)
 
## Related resources

> Use "Related resources" for architecture information that's relevant to the current article. It must be content that the Azure Architecture Center TOC refers to, but may be from a repo other than the AAC repo.
> Links to articles in the AAC repo should be repo-relative, for example (../../solution-ideas/articles/article-name.yml).
> Lead this section with links to the solution ideas that connect back to this architecture.

This solution is a generalized architecture pattern, which can be used for many different scenarios and industries. See the following example solutions that build off of this core architecture:

- [Link to first solution idea or other architecture that builds off this solution](filepath.yml)
- [Second solution idea that builds off this solution](filepath.yml)

> Include additional links to AAC articles. Here is an example:

See the following related architecture guides and solutions:

  - [Artificial intelligence (AI) - Architectural overview](/azure/architecture/data-guide/big-data/ai-overview)
  - [Choosing a Microsoft cognitive services technology](/azure/architecture/data-guide/technology-choices/cognitive-services)
  - [Chatbot for hotel reservations](/azure/architecture/example-scenario/ai/commerce-chatbot)
  - [Build an enterprise-grade conversational bot](/azure/architecture/reference-architectures/ai/conversational-bot)
  - [Speech-to-text conversion](/azure/architecture/reference-architectures/ai/speech-ai-ingestion)