support/plan:
	cd Automation/Terraform/Support && terraform plan -out=tfplan -input=false

support/apply:
	cd Automation/Terraform/Support && terraform apply -input=false tfplan

ec2/plan:
	cd Automation/Terraform/EC2 && terraform plan -out=tfplan -input=false

ec2/apply:
	cd Automation/Terraform/EC2 && terraform apply -input=false tfplan

ec2/ansible:
	cd Automation/Ansible && ansible-playbook -i inventory.yml ec2.yml

ec2/provision: ec2/plan ec2/apply ec2/ansible