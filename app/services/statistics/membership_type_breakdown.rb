module Statistics
  # Confronta gli iscritti con tipologia "Delega" (tipologia_iscrizione =
  # "Delega") con quelli "BreviManu" (il resto degli iscritti), anno su anno.
  # Riusa lo stesso fallback sull'azzonamento superiore di ZoningPeriodScope.
  class MembershipTypeBreakdown
    DELEGA = "Delega".freeze

    Row = Struct.new(:tipologia, :count_anno, :count_precedente, :diff, :diff_percent, keyword_init: true)

    def self.call(...) = new(...).call

    def initialize(zoning:, anno:, anno_precedente:, mese:)
      @zoning = zoning
      @anno = anno
      @anno_precedente = anno_precedente
      @mese = mese
    end

    def call
      [ build_row("Delega", :delega), build_row("BreviManu", :brevi_manu) ]
    end

    private

    def build_row(tipologia, kind)
      count_anno = count_for(@anno, kind)
      count_precedente = count_for(@anno_precedente, kind)
      diff = count_anno - count_precedente
      diff_percent = count_precedente.zero? ? nil : (diff.to_f / count_precedente * 100)

      Row.new(tipologia:, count_anno:, count_precedente:, diff:, diff_percent:)
    end

    def count_for(anno, kind)
      scope = ZoningPeriodScope.call(zoning: @zoning, anno:, mese: @mese)
      delega = scope.where(tipologia_iscrizione: DELEGA).count
      kind == :delega ? delega : scope.count - delega
    end
  end
end
