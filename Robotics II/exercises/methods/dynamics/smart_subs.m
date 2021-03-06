%Aurhor:    David Esteban Imnjoa Ruiz
%email:     imbajoaruiz.1922212@studenti.uniroma1.it
function [new_mat,new_dynamic_values,new_vars]=smart_subs(old_mat,to_replace,var_to_remake,independet_var_combs)
    
    new_mat=old_mat;
    new_to_replace=(to_replace);
    if(length(to_replace)>0)
        new_to_replace=expand(to_replace);
    end
    to_replace_=sym('d_',size(to_replace),'real');
    for i=1:length(to_replace)
            new_mat=subs((collect(expand(new_mat),independet_var_combs)),(collect(new_to_replace(i),independet_var_combs)),to_replace_(i));
%             new_to_replace2=subs(new_to_replace,new_to_replace(i),to_replace_(i));
            temp_collect=setdiff(symvar(new_mat),to_replace_);
            new_mat=subs(collect(expand(new_mat),temp_collect),new_to_replace(i),to_replace_(i));
            new_mat=subs(collect(expand(new_mat),new_to_replace(i)),new_to_replace(i),to_replace_(i));
            new_to_replace=subs(new_to_replace,new_to_replace(i),to_replace_(i));
    end
    total_symbols=symvar(new_mat);
%     true_sym_replace=total_symbols(find(has(total_symbols,to_replace_)))';

    [true_sym_replace_,ia,ib] = intersect(to_replace_,total_symbols);
%     true_sym_replace_=to_replace_(indexes_true_sym);
    new_dynamic_values=to_replace(ia);
    new_vars=sym(var_to_remake+"_",[length(true_sym_replace_),1],'real');
    new_mat=subs(new_mat,true_sym_replace_,new_vars);
end


