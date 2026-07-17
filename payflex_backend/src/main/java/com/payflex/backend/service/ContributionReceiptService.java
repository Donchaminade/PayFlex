package com.payflex.backend.service;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;

/**
 * Reçu PDF individuel pour UNE cotisation VALIDÉE (admin + mobile) — même bibliothèque PDFBox
 * déjà utilisée pour les exports de listes ({@code AdminExportController}), mais volontairement
 * dans un service séparé pour ne pas toucher à ce contrôleur (hors périmètre autorisé).
 */
@Service
public class ContributionReceiptService {

    private final JdbcTemplate jdbcTemplate;

    public ContributionReceiptService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public record ReceiptData(
        long id,
        String clientName,
        String clientPhone,
        double amount,
        String productName,
        String paymentMode,
        String status,
        String referenceCode,
        String createdAt
    ) {}

    /**
     * @param requireClientUserId si non nul, vérifie en plus que la cotisation appartient bien à
     *                             ce client (protection de l'endpoint mobile — un client ne doit
     *                             pouvoir télécharger que ses propres reçus).
     */
    public ReceiptData loadReceiptData(long contributionId, Long requireClientUserId) {
        ReceiptData data;
        try {
            data = jdbcTemplate.queryForObject(
                """
                SELECT c.id, u.full_name, u.phone, c.amount, COALESCE(p.name, '—') AS product_name,
                       c.payment_mode, c.status, COALESCE(c.reference_code, '') AS reference_code,
                       c.created_at, c.user_id
                FROM contributions c
                JOIN users u ON u.id = c.user_id
                LEFT JOIN products p ON p.id = c.product_id
                WHERE c.id = ?
                """,
                (rs, i) -> new ReceiptData(
                    rs.getLong("id"),
                    rs.getString("full_name"),
                    rs.getString("phone"),
                    rs.getDouble("amount"),
                    rs.getString("product_name"),
                    rs.getString("payment_mode"),
                    rs.getString("status"),
                    rs.getString("reference_code"),
                    rs.getTimestamp("created_at") != null ? rs.getTimestamp("created_at").toInstant().toString() : ""
                ),
                contributionId
            );
        } catch (EmptyResultDataAccessException ex) {
            throw new IllegalArgumentException("Cotisation introuvable.");
        }
        if (!"validated".equals(data.status())) {
            throw new IllegalArgumentException("Le reçu n'est disponible que pour une cotisation validée.");
        }
        if (requireClientUserId != null) {
            Long owner = jdbcTemplate.queryForObject("SELECT user_id FROM contributions WHERE id = ?", Long.class, contributionId);
            if (owner == null || !owner.equals(requireClientUserId)) {
                throw new IllegalArgumentException("Ce reçu n'appartient pas à ce compte.");
            }
        }
        return data;
    }

    public byte[] buildReceiptPdf(ReceiptData d) throws IOException {
        try (PDDocument document = new PDDocument()) {
            PDPage page = new PDPage(PDRectangle.A4);
            document.addPage(page);
            PDType1Font bold = new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD);
            PDType1Font regular = new PDType1Font(Standard14Fonts.FontName.HELVETICA);

            try (PDPageContentStream cs = new PDPageContentStream(document, page)) {
                float margin = 50;
                float y = 780;

                cs.setNonStrokingColor(0, 49, 79); // bleu PayFlex
                cs.addRect(margin, y - 4, PDRectangle.A4.getWidth() - 2 * margin, 46);
                cs.fill();

                cs.setNonStrokingColor(255, 255, 255);
                cs.beginText();
                cs.setFont(bold, 20);
                cs.newLineAtOffset(margin + 16, y + 12);
                cs.showText("PayFlex");
                cs.endText();
                cs.beginText();
                cs.setFont(regular, 10);
                cs.newLineAtOffset(margin + 16, y - 4);
                cs.showText("Reçu de cotisation");
                cs.endText();

                cs.setNonStrokingColor(0, 0, 0);
                y -= 70;

                cs.beginText();
                cs.setFont(bold, 13);
                cs.newLineAtOffset(margin, y);
                cs.showText("Reçu n° " + d.id());
                cs.endText();
                y -= 30;

                y = writeRow(cs, regular, bold, margin, y, "Client", d.clientName());
                y = writeRow(cs, regular, bold, margin, y, "Téléphone", d.clientPhone() != null ? d.clientPhone() : "—");
                y = writeRow(cs, regular, bold, margin, y, "Produit", d.productName());
                y = writeRow(cs, regular, bold, margin, y, "Montant", Math.round(d.amount()) + " FCFA");
                y = writeRow(cs, regular, bold, margin, y, "Mode de paiement", AdminAuditService.modePaiement(d.paymentMode()));
                y = writeRow(cs, regular, bold, margin, y, "Statut", AdminAuditService.statutCotisation(d.status()));
                y = writeRow(cs, regular, bold, margin, y, "Référence", d.referenceCode() == null || d.referenceCode().isBlank() ? "—" : d.referenceCode());
                y = writeRow(cs, regular, bold, margin, y, "Date", d.createdAt());

                y -= 20;
                cs.setStrokingColor(200, 200, 200);
                cs.moveTo(margin, y);
                cs.lineTo(PDRectangle.A4.getWidth() - margin, y);
                cs.stroke();
                y -= 20;

                cs.beginText();
                cs.setFont(regular, 9);
                cs.newLineAtOffset(margin, y);
                cs.showText("Document généré automatiquement par PayFlex — conserver comme preuve de versement.");
                cs.endText();
            }

            ByteArrayOutputStream out = new ByteArrayOutputStream();
            document.save(out);
            return out.toByteArray();
        }
    }

    private float writeRow(
        PDPageContentStream cs,
        PDType1Font regular,
        PDType1Font bold,
        float margin,
        float y,
        String label,
        String value
    ) throws IOException {
        cs.beginText();
        cs.setFont(bold, 11);
        cs.newLineAtOffset(margin, y);
        cs.showText(label + " :");
        cs.endText();

        cs.beginText();
        cs.setFont(regular, 11);
        cs.newLineAtOffset(margin + 150, y);
        cs.showText(value == null ? "—" : value);
        cs.endText();

        return y - 22;
    }
}
