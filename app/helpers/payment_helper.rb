module PaymentHelper

    def payment_info(params)
        if Semantic.count > 0 and Semantic.first.validation.to_s != ""
            # check data format in configuration
            init = RDF::Repository.new()
            init << RDF::Reader.for(:trig).new(Semantic.first.validation.to_s)
            ic = nil
            init.each_graph{ |g| g.graph_name == SEMCON_ONTOLOGY + "BaseConfiguration" ? ic = g : nil }
            RDF::Query.execute(ic) { pattern [:subject, RDF::URI.new(SEMCON_ONTOLOGY + "hasPaymentInfo"), :value] }.first.value.to_s rescue ""
        else
            ""
        end
    end

    def payment_methods
        ["Ether"]
    end

    def payment_seller_email
        if Semantic.count > 0 and Semantic.first.validation.to_s != ""
            # check data format in configuration
            init = RDF::Repository.new()
            init << RDF::Reader.for(:trig).new(Semantic.first.validation.to_s)
            ic = nil
            init.each_graph{ |g| g.graph_name == SEMCON_ONTOLOGY + "BaseConfiguration" ? ic = g : nil }
            RDF::Query.execute(ic) { pattern [:subject, RDF::URI.new(SEMCON_ONTOLOGY + "hasSellerEmail"), :value] }.first.value.to_s rescue nil
        else
            nil
        end
    end

    def payment_seller_pubkey_id
        if Semantic.count > 0 and Semantic.first.validation.to_s != ""
            # check data format in configuration
            init = RDF::Repository.new()
            init << RDF::Reader.for(:trig).new(Semantic.first.validation.to_s)
            ic = nil
            init.each_graph{ |g| g.graph_name == SEMCON_ONTOLOGY + "BaseConfiguration" ? ic = g : nil }
            RDF::Query.execute(ic) { pattern [:subject, RDF::URI.new(SEMCON_ONTOLOGY + "hasSellerPubkeyID"), :value] }.first.value.to_s rescue nil
        else
            nil
        end
    end

    def payment_billing_service_url
        bc = nil
        image_constraints = RDF::Repository.load("./config/image-constraints.trig", format: :trig)
        image_constraints.each_graph{ |g| g.graph_name == SEMCON_ONTOLOGY + "ImageConfiguration" ? bc = g : nil }
        billing_service_url = RDF::Query.execute(bc) { pattern [:subject, RDF::URI.new(SEMCON_ONTOLOGY + "billingService"), :value] }.first.value.to_s rescue ""
        if billing_service_url == ""
            billing_service_url = "http://srv-billing:3000"
        end
        billing_service_url
    end

end