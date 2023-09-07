destroy_elb() {
    for lb in ${REMAINING_LB} ; do
        echo "Attempting to destroy ELBv2 ${lb}..."
        aws elbv2 delete-load-balancer --load-balancer-arn ${lb} --region ${AWS_REGION} && echo "Destroy ELBv2 ${lb} attempt was success."
            if [[ $? -ne 0 ]] ; then
                echo "An attempt to destroy ${lb} as ELBv2 type failed."
                echo "Attempting to destroy ${lb} as ELBv1 type ..."
                lb_name=$(echo ${lb} | sed -n -e 's/^.*\:loadbalancer\/// p')
                aws elb delete-load-balancer --load-balancer-name ${lb_name} --region ${AWS_REGION}
                if [[ $? -eq 0 ]] ; then
                    echo "Destroy ELBv1 ${lb_name} attempt was success."
                else
                    echo "Destroy of ELB ${lb_name} Failed. Error."
                fi
            fi
    done
}


destroy_asg() {
    for asg in ${REMAINING_ASG} ; do
        echo "Attempting to destroy ASG ${asg}..."
        aws autoscaling delete-auto-scaling-group --auto-scaling-group-name ${asg} --force-delete --region ${AWS_REGION}
        if [[ $? -eq 0 ]] ; then
            echo "Destroy ASG ${asg} attempt was success."
        else
            echo "Destroy of ASG ${asg} Failed. Error."
        fi
    done
}


destroy_tg() {
    for tg in ${REMAINING_TG} ; do
        echo "Attempting to destroy ${tg}..."
        aws elbv2 delete-target-group --target-group-arn ${tg} --region ${AWS_REGION}
        if [[ $? -eq 0 ]] ; then
            echo "Destroy TG ${tg} attempt was success."
        else
            echo "Destroy of TG ${tg} Failed. Error."
        fi
    done
}


destroy_vl() {
    for vl in ${REMAINING_VL} ; do
        echo "Attempting to destroy ${vl}..."
        aws ec2 delete-volume --volume-id ${vl}
        if [[ $? -eq 0 ]] ; then
            echo "Destroy EBS volume ${vl} attempt was success."
        else
            echo "Destroy of EBS volume ${vl} Failed. Error."
        fi
    done
}


destroy_sg() {
    for sg in ${REMAINING_SG} ; do
        echo "Attempting to destroy ${sg}..."
        aws ec2 delete-security-group --group-id ${sg} --region ${AWS_REGION}
        if [[ $? -eq 0 ]] ; then
            echo "Destroy SG ${sg} attempt was success."
        else
            echo "Destroy of SG ${sg} Failed."
        fi
    done
}
