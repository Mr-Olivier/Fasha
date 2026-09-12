package rw.kazilink.provider;

import java.math.BigDecimal;

public record EarningsSummaryResponse(BigDecimal totalEarned, long jobCount, String periodLabel) {
}
